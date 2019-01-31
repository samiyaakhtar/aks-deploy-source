cd /home/vsts/work/1/s/

# If the version number is not provided, then download the latest
if [ -z "$VERSION" ]
then
    VERSIONS=$(curl -s https://api.github.com/repos/Microsoft/fabrikate/tags)
    LATEST_RELEASE=$(echo $VERSIONS | grep "name" | head -1)
    VERSION_TO_DOWNLOAD=`echo "$LATEST_RELEASE" | cut -d'"' -f 4`
else
    echo "Fabrikate Version: $VERSION"
    VERSION_TO_DOWNLOAD=$VERSION
fi

echo "RUN HELM INIT"
helm init
echo "HELM ADD INCUBATOR"
echo "HELM_CHART_REPO:$HELM_CHART_REPO"
echo "HELM_CHART_REPO_URL:$HELM_CHART_REPO_URL"
if [ -z "$HELM_CHART_REPO"] && [ -z "$HELM_CHART_REPO_URL"]
then
    echo "Using DEFAULT helm repo..."
    helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/
else
    echo "Using DEFINED help repo..."
    helm repo add $HELM_CHART_REPO $HELM_CHART_REPO_URL
fi

echo "Downloading Fabrikate..."
echo "Latest Fabrikate Version: $VERSION_TO_DOWNLOAD"
wget "https://github.com/Microsoft/fabrikate/releases/download/$VERSION_TO_DOWNLOAD/fab-v$VERSION_TO_DOWNLOAD-linux-amd64.zip"
unzip fab-v$VERSION_TO_DOWNLOAD-linux-amd64.zip -d fab
export PATH=$PATH:/home/vsts/work/1/s/fab
fab install

fab generate prod
echo "FAB GENERATE PROD COMPLETED"
ls -a

# If generated folder is empty, quit
# In the case that all components are removed from the source hld, 
# generated folder should still not be empty
if find "/home/vsts/work/1/s/generated" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
    echo "Manifest files have been generated"
else
    echo "Manifest files could not be generated, quitting"
    exit 1
fi