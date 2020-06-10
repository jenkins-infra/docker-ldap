package main

import (
	"fmt"
	"log"
	"os"

	"bytes"

	"encoding/csv"
	"encoding/json"
	"io/ioutil"
	"net/http"

	"time"

	"github.com/spf13/cobra"
	ldap "gopkg.in/ldap.v3"
)

const (
	URL_ARTIFACTORY_LDAP_USER_REPORT string = "https://reports.jenkins.io/artifactory-ldap-users-report.json"

	ldapDateLayout string = "2006/01/02 15:04:05"
	jiraDateLayout string = "2006-01-02 15:04:05"
	restoredDate   string = "2020/06/02 00:00:00"
	backupDate     string = "2020/02/01 00:00:00"
)

var (
	rootCmd = &cobra.Command{
		Use:   "getUserAccounts",
		Short: "Return jenkins users account",
		Run: func(cmd *cobra.Command, args []string) {
			run()
		},
	}

	maintainerCmd = &cobra.Command{
		Use:   "maintainer",
		Short: "Return list of maintainers",
		Run: func(cmd *cobra.Command, args []string) {
			getMaintainers()
		},
	}

	jiraCmd = &cobra.Command{
		Use:   "jira",
		Short: "Return list of users found in Jira database backup file",
		Run: func(cmd *cobra.Command, args []string) {
			getJiraUsers()
		},
	}

	bindUsername        string
	bindPassword        string
	jiraUsername        string
	jiraPassword        string
	url                 string
	port                int
	protocol            string
	groupBaseDN         string
	newAccounts         [][]string = [][]string{{"cn", "mail", "creation_date", "github"}}
	newAccountsFilePath string
	memberOfGroup       string
	userBaseDN          string

	jiraBackupFile string

	//maintainerCmd Option
	showIfMaintainerRecordedInLdap    bool
	showIfMaintainerNotRecordedInLdap bool
)

type User struct {
	UserName     string
	FirstName    string
	LastName     string
	DisplayName  string
	Email        string
	CreationDate string
	ModifiedDate string
}

func (u *User) ShowCSV() {
	fmt.Printf("%s:%s:%s:%s:%s:%s:%s\n", u.UserName, u.FirstName, u.LastName, u.DisplayName, u.Email, u.CreationDate, u.ModifiedDate)
}

func (u *User) ShowLDIF() {
	fmt.Printf("dn: cn=%s, ou=people, dc=jenkins-ci,dc=org\n", u.UserName)
	fmt.Printf("objectClass: inetOrgPerson\n")
	fmt.Printf("businessCategory: N\n")
	fmt.Printf("carLicense: %s\n", u.CreationDate)
	fmt.Printf("cn: %s\n", u.UserName)
	fmt.Printf("mail: %s\n", u.Email)
	fmt.Printf("givenName: %s\n", u.FirstName)
	fmt.Printf("sn: %s\n", u.LastName)
	fmt.Printf("userPassword: XXX\n")
	fmt.Printf("\n")
}

func init() {

	rootCmd.AddCommand(
		maintainerCmd,
		jiraCmd,
	)

	rootCmd.PersistentFlags().StringVar(&bindUsername, "username", "cn=admin,dc=jenkins-ci,dc=org", "Define ldap bind username")
	rootCmd.PersistentFlags().StringVar(&bindPassword, "password", "", "Define ldap bind password")
	rootCmd.PersistentFlags().StringVar(&jiraUsername, "jiraUsername", "", "Define jira bind username")
	rootCmd.PersistentFlags().StringVar(&jiraPassword, "jiraPassword", "", "Define jira password")
	rootCmd.PersistentFlags().StringVar(&url, "url", "localhost", "Define ldap url")
	rootCmd.PersistentFlags().StringVar(&protocol, "protocol", "ldaps", "Define ldap protocol [ldap, ldaps]")
	rootCmd.PersistentFlags().IntVar(&port, "port", 389, "Define ldap url")
	rootCmd.PersistentFlags().StringVar(&groupBaseDN, "groupBaseDN", "ou=groups,dc=jenkins-ci,dc=org", "Define group search base dn")
	rootCmd.PersistentFlags().StringVar(&userBaseDN, "userBaseDN", "ou=people,dc=jenkins-ci,dc=org", "Define user search base dn")
	rootCmd.PersistentFlags().StringVar(&memberOfGroup, "memberOfGroup", "all", "Define required group membership")
	rootCmd.PersistentFlags().StringVar(&newAccountsFilePath, "file-new", "accounts.new.csv", "Define the csv file where new jenkins accounts are exported")

	rootCmd.PersistentFlags().BoolVar(&showIfMaintainerRecordedInLdap, "show-exist", false, "Display artifactory maintainers that exist in Ldap database")
	rootCmd.PersistentFlags().BoolVar(&showIfMaintainerNotRecordedInLdap, "show-not-exist", false, "Display artifactory maintainers that don't exist in Ldap database")

	jiraCmd.Flags().StringVar(&jiraBackupFile, "backup-file", "", "Read Jira backup file using csv with following fields <user_name,first_name,last_name,display_name,email_address,created_date,updated_date>")

	rootCmd.MarkFlagRequired("password")
}

func getArtifactoryMaintainers() ([]string, error) {

	req, err := http.NewRequest("GET", URL_ARTIFACTORY_LDAP_USER_REPORT, nil)

	if err != nil {
		return nil, err
	}

	res, err := http.DefaultClient.Do(req)

	if err != nil {
		return nil, err
	}

	defer res.Body.Close()

	body, err := ioutil.ReadAll(res.Body)

	if err != nil {
		return nil, err
	}

	u := []string{}

	err = json.Unmarshal(body, &u)
	if err != nil {
		log.Println(err)
	}

	return u, nil
}

func getJiraUsers() {
	// getJiraUsers() return the list of user from issues.jenkins-ci.org and compare it to LDAP database

	existCounter := 0
	notExistCounter := 0

	sr, err := getLdapUsers()
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Compare Jira users based on csv")

	users, err := getJiraUsersFromFile()

	if err != nil {
		log.Println(err)
	}

	for _, user := range users {
		exist := false

		for _, entry := range sr.Entries {

			if user.UserName == entry.GetAttributeValue("cn") {
				exist = true
			}
		}
		if exist {
			existCounter++
			if showIfMaintainerRecordedInLdap == true {
				fmt.Printf("Maintainer %s found in database\n", user)
			}
		} else {
			notExistCounter++
			if showIfMaintainerNotRecordedInLdap == true {
				fmt.Printf("Maintainer %s not found in database\n", user)
				// fmt.Printf("https://accounts.jenkins.io/admin/signup?userId=%s&firstName=John&lastName=Doe&email=jenkins-%s%%40olblak.com\n", user, user)
			}
		}
	}

	fmt.Printf("%d Jira account already exist in ldap\n", existCounter)
	fmt.Printf("Based on Jira %d account need to be recreated in DB\n", notExistCounter)
}

func getMaintainers() {
	// getMaintainer returns the list of maintainers from repos.jenkins-ci.org and compare it to LDAP database

	existCounter := 0
	notExistCounter := 0

	sr, err := getLdapUsers()
	if err != nil {
		log.Fatal(err)
	}

	users, err := getArtifactoryMaintainers()

	for _, user := range users {
		exist := false

		for _, entry := range sr.Entries {

			if user == entry.GetAttributeValue("cn") {
				exist = true
			}
		}
		if exist {
			existCounter++
			if showIfMaintainerRecordedInLdap == true {
				fmt.Printf("Maintainer %s found in database\n", user)
			}
		} else {
			notExistCounter++
			if showIfMaintainerNotRecordedInLdap == true {
				fmt.Printf("Maintainer %s not found in database\n", user)
			}
		}
	}

	fmt.Printf("%d maintainers are presents in LDAP database\n", existCounter)
	fmt.Printf("%d maintainers are NOT presents in LDAP database\n", notExistCounter)

	fmt.Printf("\n\nShow recent maintainers created after %s\n\n", restoredDate)

	for _, entry := range sr.Entries {

		creationDate := entry.GetAttributeValue("carLicense")
		github := entry.GetAttributeValue("employeeNumber") // Contains github account
		mail := entry.GetAttributeValue("mail")
		cn := entry.GetAttributeValue("cn")

		if len(github) == 0 {
			github = "unknown"
		}

		date, err := time.Parse(ldapDateLayout, creationDate)

		if err != nil && creationDate != "" {
			log.Print(err)
		}

		pivotDate, err := time.Parse(ldapDateLayout, restoredDate)
		if err != nil {
			log.Print(err)

		}

		if date.After(pivotDate) {
			for _, user := range users {
				if cn == user {
					//fmt.Printf("%s\n", showJiraUserInfo(user))
					//fmt.Printf("Maintainer %s (Github: %s, Mail: %s) re-created his account on the %s\n", cn, github, mail, creationDate)
					fmt.Printf("%s,%s,%s,%s\n", cn, mail, creationDate, github)
				}
			}
		}
	}
}

func getJiraUsersFromFile() ([]User, error) {

	/*
		  Jira user list retrieved with
			mysql -h hostname -u user -P 3306 -p  database_name --batch --raw -e 'select user_name, first_name, last_name, display_name, email_address, created_date, updated_date from cwd_user where active='1';' > users.csv

	*/

	jiraUsers := []User{}

	data, err := ioutil.ReadFile(jiraBackupFile)
	raw := csv.NewReader(bytes.NewReader(data))

	users, err := raw.ReadAll()

	if err != nil {
		return nil, err
	}

	pivotDate, err := time.Parse(ldapDateLayout, backupDate)
	if err != nil {
		log.Print(err)

	}

	fmt.Printf("%d users retrieved\n", len(users))

	for _, user := range users {
		u := User{
			UserName:     user[0],
			FirstName:    user[1],
			LastName:     user[2],
			DisplayName:  user[3],
			Email:        user[4],
			CreationDate: user[5],
			ModifiedDate: user[6],
		}

		date, err := time.Parse(jiraDateLayout, u.CreationDate)

		if err != nil && u.CreationDate != "" {
			log.Print(err)
			return nil, err
		}

		if date.After(pivotDate) {
			jiraUsers = append(jiraUsers, u)
			//u.ShowCSV()
			//u.ShowLDIF()
		}
	}

	fmt.Printf("%d Jira users created after %s\n", len(jiraUsers), pivotDate)

	return jiraUsers, nil
}

func showJiraUserInfo(user string) error {
	// Show user information based on jira user search api

	URL := fmt.Sprintf("https://issues.jenkins-ci.org/rest/api/2/user/search?username=%s&maxResults=100&startAt=0", user)

	req, err := http.NewRequest("GET", URL, nil)

	req.SetBasicAuth(jiraUsername, jiraPassword)

	if err != nil {
		return err
	}

	res, err := http.DefaultClient.Do(req)

	if err != nil {
		return err
	}

	defer res.Body.Close()

	body, err := ioutil.ReadAll(res.Body)

	if err != nil {
		return err
	}

	fmt.Printf("%s\n", string(body))

	return nil
}

func getLdapUsers() (sr *ldap.SearchResult, err error) {

	l, err := ldap.DialURL(fmt.Sprintf("%v://%s:%d", protocol, url, port))

	if err != nil {
		return sr, err
	}

	defer l.Close()

	err = l.Bind(bindUsername, bindPassword)
	if err != nil {
		return sr, err
	}

	searchRequest := ldap.NewSearchRequest(
		userBaseDN,
		ldap.ScopeWholeSubtree, ldap.NeverDerefAliases, 0, 0, false,
		"(&(objectClass=inetOrgPerson))",
		[]string{
			"cn",
			"mail",
			"carLicense",
			"employeeNumber"},
		nil,
	)

	sr, err = l.Search(searchRequest)
	if err != nil {
		return sr, err
	}
	return sr, nil
}

func run() {

}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
