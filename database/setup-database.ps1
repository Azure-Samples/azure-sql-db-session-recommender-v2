Invoke-WebRequest -Uri https://aka.ms/sqlpackage-linux -OutFile sqlpackage.zip

Expand-Archive ./sqlpackage.zip sqlpackage/

chmod a+x ./sqlpackage/sqlpackage

./sqlpackage/sqlpackage /version

Write-Host "Downloading dacpacs"

Invoke-WebRequest -Uri https://github.com/yorek/session_recommender_v2/raw/main/database/session_recommender_v2.dacpac -OutFile session_recommender_v2.dacpac
Invoke-WebRequest -Uri https://github.com/yorek/session_recommender_v2/raw/main/database/master.dacpac -OutFile master.dacpac

Write-Host "Deploying database to $Env:DBSERVER with name $Env:DBNAME"

./sqlpackage/sqlpackage `
    /Action:Publish `
    /SourceFile:"session_recommender_v2.dacpac" `
    /TargetDatabaseName:"$Env:DBNAME" `
    /TargetServerName:"$Env:DBSERVER" `
    /TargetUser:"$Env:SQLADMIN" `
    /TargetPassword:"$Env:SQLCMDPASSWORD" `
    /v:OPEN_AI_ENDPOINT="$Env:OPEN_AI_ENDPOINT" `
    /v:OPEN_AI_DEPLOYMENT="$Env:OPEN_AI_DEPLOYMENT" `
    /v:OPEN_AI_KEY="$Env:OPEN_AI_KEY" `
    /v:APP_USER_PASSWORD="$Env:APP_USER_PASSWORD"
