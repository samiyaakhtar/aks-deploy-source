
echo "Downloading Fabrikate..."
cd /home/vsts/work/1/s/

if [ -z "$VERSION" ]
then
    VERSIONS=$(curl -s https://api.github.com/repos/Microsoft/fabrikate/tags)
    LATEST_RELEASE=$(echo $VERSIONS | grep "name" | head -1)
    LATEST_VERSION=`echo "$LATEST_RELEASE" | cut -d'"' -f 4`
else
    echo "Fabrikate Version: $VERSION"
fi

echo "Latest Fabrikate Version: $LATEST_VERSION"
wget "https://github.com/Microsoft/fabrikate/releases/download/$LATEST_VERSION/fab-v-linux-amd64.zip"

unzip fab-v-linux-amd64.zip -d fab
export PATH=$PATH:/home/vsts/work/1/s/fab

set -e

echo "Running Fabrikate..."
fab install
fab generate prod

# If generated folder is empty, quit
if find "/home/vsts/work/1/s/generated" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
    echo "Files have been generated"
else
    echo "Files could not be generated, quitting"
    exit 1
fi

git --version
cd /home/vsts/work/1/s/
git clone https://github.com/samiyaakhtar/aks-deploy-destination.git
cd aks-deploy-destination
git checkout master

echo "Copying generated files"
rm -rf prod/
cp -r /home/vsts/work/1/s/generated/* .
echo "git add *"
git add *
ls
echo "setup author info"
git config user.email "me@samiya.ca"
git config user.name "azure-pipelines[bot]"
echo "git commit with message"
git commit --allow-empty -a -m "Updating files post commit - $COMMIT_MESSAGE"
git remote set-url origin git@github.com:samiyaakhtar/aks-deploy-destination.git
git status
echo "git push with token"
git push https://$ACCESS_TOKEN@github.com/samiyaakhtar/aks-deploy-destination.git