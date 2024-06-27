using System;
using System.Collections.Generic;
using System.Text;
using DbUp;
using DbUp.ScriptProviders;
using DotNetEnv;
using Microsoft.Data.SqlClient;

namespace Database.Deploy
{
    class Program
    {
        static int Main(string[] args)
        {
            // This will load the content of .env and create related environment variables
            DotNetEnv.Env.Load("../.env");            

            // Connection string for deploying the database (high-privileged account as it needs to be able to CREATE/ALTER/DROP)
            var connectionString = Env.GetString("MSSQL");
            
            if (string.IsNullOrEmpty(connectionString)) {
                Console.WriteLine("ERROR: 'ConnectionString' enviroment variable not set or empty.");
                Console.WriteLine("You can create an .env file in parent folder that sets the 'MSSQL' environment variable; then run this app again.");                
                return 1;
            }
            
            var csb = new SqlConnectionStringBuilder(connectionString);
            Console.WriteLine($"Deploying database: {csb.InitialCatalog}");

            Console.WriteLine("Testing connection...");
            var conn = new SqlConnection(csb.ToString());
            conn.Open();
            conn.Close();

            FileSystemScriptOptions options = new() {
                IncludeSubDirectories = false,
                Extensions = ["*.sql"],
                Encoding = Encoding.UTF8
            };

            Dictionary<string, string> variables = new() {
                {"OPENAI_URL", Env.GetString("OPENAI_URL")},
                {"OPENAI_KEY", Env.GetString("OPENAI_KEY")}
            };

            Console.WriteLine("Starting deployment...");
            var dbup = DeployChanges.To
                .SqlDatabase(csb.ConnectionString)
                .WithVariables(variables)
                .WithScriptsFromFileSystem("sql", options)
                .JournalToSqlTable("dbo", "$__dbup_journal")                                               
                .LogToConsole()
                .Build();
         
            var result = dbup.PerformUpgrade();

            if (!result.Successful)
            {
                Console.WriteLine(result.Error);
                return -1;
            }

            Console.WriteLine("Success!");
            return 0;
        }
    }
}
