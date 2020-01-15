package main

import (
	"encoding/csv"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/spf13/cobra"
	ldap "gopkg.in/ldap.v3"
)

const (
	ldapDateLayout string = "2006/01/02 15:04:05"
)

var (
	rootCmd = &cobra.Command{
		Use:   "exportJenkinsAccounts",
		Short: "Export jenkins account into csv files",
		Run: func(cmd *cobra.Command, args []string) {
			run()
		},
	}
	bindUsername           string
	bindPassword           string
	url                    string
	port                   int
	protocol               string
	groupBaseDN            string
	seniorityCriteriaDate  string
	seniorAccounts         [][]string = [][]string{{"cn", "mail", "creation_date", "github"}}
	newAccounts            [][]string = [][]string{{"cn", "mail", "creation_date", "github"}}
	seniorAccountsFilePath string
	newAccountsFilePath    string
	memberOfGroup          string
)

func init() {
	rootCmd.Flags().StringVar(&bindUsername, "username", "cn=admin,dc=jenkins-ci,dc=org", "Define ldap bind username")
	rootCmd.Flags().StringVar(&bindPassword, "password", "", "Define ldap bind password")
	rootCmd.Flags().StringVar(&url, "url", "localhost", "Define ldap url")
	rootCmd.Flags().StringVar(&protocol, "protocol", "ldaps", "Define ldap protocol [ldap, ldaps]")
	rootCmd.Flags().IntVar(&port, "port", 389, "Define ldap url")
	rootCmd.Flags().StringVar(&groupBaseDN, "groupBaseDN", "ou=groups,dc=jenkins-ci,dc=org", "Define group search base dn")
	rootCmd.Flags().StringVar(&memberOfGroup, "memberOfGroup", "all", "Define required group membership")
	rootCmd.Flags().StringVar(&seniorityCriteriaDate, "seniorityCriteriaDate", "2019/09/01 00:00:00", "Define the date limit when a jenkins account is considered as senior member")
	rootCmd.Flags().StringVar(&seniorAccountsFilePath, "file-senior", "accounts.csv", "Define the csv file where senior jenkins accounts are exported")
	rootCmd.Flags().StringVar(&newAccountsFilePath, "file-new", "accounts.new.csv", "Define the csv file where new jenkins accounts are exported")

	rootCmd.MarkFlagRequired("password")
}

func writeCSV(filepath string, data [][]string) error {
	f, err := os.Create(filepath)
	if err != nil {
		log.Fatalln(err)
		return err
	}
	defer f.Close()

	w := csv.NewWriter(f)
	w.WriteAll(data)

	if err := w.Error(); err != nil {
		log.Fatalln("error writing csv:", err)
		return err
	}
	return nil
}

func run() {
	l, err := ldap.DialURL(fmt.Sprintf("%v://%s:%d", protocol, url, port))

	if err != nil {
		log.Fatal(err)
	}

	defer l.Close()

	err = l.Bind(bindUsername, bindPassword)
	if err != nil {
		log.Fatal(err)
	}

	searchRequest := ldap.NewSearchRequest(
		groupBaseDN,
		ldap.ScopeWholeSubtree, ldap.NeverDerefAliases, 0, 0, false,
		fmt.Sprintf("(&(objectClass=groupOfNames)(cn=%s))", memberOfGroup),
		[]string{"member"},
		nil,
	)

	sr, err := l.Search(searchRequest)
	if err != nil {
		log.Fatal(err)
	}

	if len(sr.Entries) != 1 {
		log.Fatalln("Something went wrong with the group search:", memberOfGroup)
	}

	for id, member := range sr.Entries[0].Attributes[0].Values {
		// In jenkins ldap database, carLicense contains the account creation date and employeeNumber the github_id
		fmt.Printf("User #%v: %v\n", id+1, member)

		searchRequest = ldap.NewSearchRequest(
			member,
			ldap.ScopeWholeSubtree, ldap.NeverDerefAliases, 0, 1, false,
			"(&(objectClass=inetOrgPerson))",
			[]string{"cn", "mail", "carLicense", "employeeNumber"},
			nil,
		)
		sr, err = l.Search(searchRequest)
		if err != nil {
			log.Print(err)
			continue
		}

		cn := sr.Entries[0].GetAttributeValue("cn")
		mail := sr.Entries[0].GetAttributeValue("mail")
		creationDate := sr.Entries[0].GetAttributeValue("carLicense")       // Contains creation_date
		githubUsername := sr.Entries[0].GetAttributeValue("employeeNumber") // Contains github_id

		date, err := time.Parse(ldapDateLayout, creationDate)
		if err != nil && creationDate != "" {
			log.Print(err)
		}

		pivotDate, err := time.Parse(ldapDateLayout, seniorityCriteriaDate)
		if err != nil {
			log.Print(err)

		}
		// Only reject users with an account created after seniorityCriteriaDate and we assume that
		// users without creation_date were created before 2015/22/11 (https://git.io/JeGCl)

		if date.After(pivotDate) {
			newAccounts = append(newAccounts, []string{cn, mail, creationDate, githubUsername})
			continue
		}

		seniorAccounts = append(seniorAccounts, []string{cn, mail, creationDate, githubUsername})
	}

	writeCSV(seniorAccountsFilePath, seniorAccounts)
	writeCSV(newAccountsFilePath, newAccounts)
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
