#!/bin/bash

req() {
    wget --header="User-Agent: Mozilla/5.0 (Android 13; Mobile; rv:125.0) Gecko/125.0 Firefox/125.0" \
         --header="Content-Type: application/octet-stream" \
         --header="Accept-Language: en-US,en;q=0.9" \
         --header="Connection: keep-alive" \
         --header="Upgrade-Insecure-Requests: 1" \
         --header="Cache-Control: max-age=0" \
         --header="Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" \
         --keep-session-cookies --timeout=30 -nv -O "$@"
}

download_resources() {
    githubApiUrl="https://api.github.com/repos/inotia00/revanced-patches/releases/latest"
    page=$(req - 2>/dev/null $githubApiUrl)
    assetUrls=$(echo $page | perl utils/extract_github.pl)
    while read -r downloadUrl assetName; do
        req "$assetName" "$downloadUrl" 
    done <<< "$assetUrls"
}

# Best but sometimes not work because APKmirror protection 
apkmirror() {
    org="$1" name="$2" package="$3" arch="${4:-universal}" dpi="${5:-nodpi}"
    version=$(cat patches.json | perl utils/extract_supported_version.pl "$package")
    url="https://www.apkmirror.com/uploads/?appcategory=$name"
    version="${version:-$(req - $url | perl utils/apkmirror_versions.pl | perl utils/largest_version.pl)}"
    url="https://www.apkmirror.com/apk/$org/$name/$name-${version//./-}-release"
    url=$(req - $url | perl utils/apkmirror_dl_page.pl $dpi $arch)
    url=$(req - $url | perl utils/apkmirror_dl_link.pl)
    url=$(req - $url | perl utils/apkmirror_final_link.pl)
    req $name-v$version.apk $url
}

# X not work (maybe more)
uptodown() {  
    name=$1 package=$2
    version=$(cat patches.json | perl utils/extract_supported_version.pl "$package")    url="https://$name.en.uptodown.com/android/versions"
    version="${version:-$(req - 2>/dev/null $url | perl utils/uptodown_latest_version.pl)}"
    url=$(req - $url | perl utils/uptodown_dl_page.pl $version)
    url=$(req - $url | perl utils/uptodown_final_link.pl)
    req $name-v$version.apk $url
}

# Tiktok not work because not available version supported 
apkpure() {   
    name=$1 package=$2
    url="https://apkpure.net/$name/$package/versions"
    version=$(cat patches.json | perl utils/extract_supported_version.pl "$package")
    version="${version:-$(req - $url | perl utils/apkpure_latest_version.pl)}"
    url="https://apkpure.net/$name/$package/download/$version"
    url=$(req - $url | perl utils/apkpure_dl_link.pl $package)
    req $name-v$version.apk $url
}

download_resources

apkmirror "google-inc" \
          "youtube-music" \
          "com.google.android.apps.youtube.music" \
          "arm64-v8a"          

apkmirror "google-inc" \
          "youtube" \
          "com.google.android.youtube"

apkpure "youtube-music" \
        "com.google.android.apps.youtube.music" 

apkpure "youtube" \
        "com.google.android.youtube" 

uptodown "youtube-music" \
         "com.google.android.apps.youtube.music" 

uptodown "youtube" \
         "com.google.android.youtube"
