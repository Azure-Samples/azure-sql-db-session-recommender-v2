sudo cp ./scripts/ms-repo.pref /etc/apt/preferences.d/

export dotnet_version="8.0"
export dab_version="1.1.7"
export sqlcmd_version="1.6.0"
export func_version="4"
export sqlprj_version="0.1.19-preview"

export debian_version=$(if command -v lsb_release &> /dev/null; then lsb_release -r -s; else grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"'; fi)

wget https://packages.microsoft.com/config/debian/$debian_version/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt update

sudo apt install dotnet-sdk-$dotnet_version -y

npm install -g azure-functions-core-tools@$func_version --unsafe-perm true

npm install -g @azure/static-web-apps-cli

dotnet tool install -g microsoft.sqlpackage
dotnet new install Microsoft.Build.Sql.Templates::$sqlprj_version

dotnet tool install -g Microsoft.DataApiBuilder --version $dab_version

sudo apt-get install sqlcmd
sudo wget https://github.com/microsoft/go-sqlcmd/releases/download/v$sqlcmd_version/sqlcmd-v$sqlcmd_version-linux-amd64.tar.bz2
sudo bunzip2 sqlcmd-v$sqlcmd_version-linux-amd64.tar.bz2
sudo tar xvf sqlcmd-v$sqlcmd_version-linux-amd64.tar
sudo mv sqlcmd /usr/bin/sqlcmd
sudo rm sqlcmd-v$sqlcmd_version-linux-amd64.tar
sudo rm sqlcmd_debug
sudo rm NOTICE.md

if [[ ":$PATH:" == *":$HOME/.dotnet/tools:"* ]]; then
  echo "Path already includes ~/.dotnet/tools, skipping."
else
  echo "Adding ~/.dotnet/tools to path."
  echo 'PATH=$PATH:$HOME/.dotnet/tools' >> ~/.bashrc
fi