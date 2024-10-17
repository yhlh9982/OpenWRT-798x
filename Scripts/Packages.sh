#!/bin/bash

#安装和更新软件包
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local REPO_NAME=$(echo $PKG_REPO | cut -d '/' -f 2)

	rm -rf $(find ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune)

	git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git"

	if [[ $PKG_SPECIAL == "pkg" ]]; then
		cp -rf $(find ./$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune) ./
		rm -rf ./$REPO_NAME/
	elif [[ $PKG_SPECIAL == "name" ]]; then
		mv -f $REPO_NAME $PKG_NAME
	fi
}

#UPDATE_PACKAGE "包名" "项目地址" "项目分支" "pkg/name，可选，pkg为从大杂烩中单独提取包名插件；name为重命名为包名"
UPDATE_PACKAGE "argon" "jerrykuku/luci-theme-argon" "master"
UPDATE_PACKAGE "argon-config" "jerrykuku/luci-app-argon-config" "master"
UPDATE_PACKAGE "kucat" "sirpdboy/luci-theme-kucat" "js"  #酷猫主题
UPDATE_PACKAGE "advancedplus" "VIKINGYFY/luci-app-advancedplus" "main"  #酷猫主题设置
UPDATE_PACKAGE "alpha" "derisamedia/luci-theme-alpha" "master"
UPDATE_PACKAGE "alpha-config" "animegasan/luci-app-alpha-config" "master"

#添加应用
#UPDATE_PACKAGE "luci-app-adguardhome" "sirpdboy/sirpdboy-package" "main" "pkg"   #adguard home
#UPDATE_PACKAGE "luci-app-ikoolproxy" "ilxp/luci-app-ikoolproxy" "main"   #iKoolProxy 滤广告
#UPDATE_PACKAGE "luci-app-adbyby-plus" "coolsnowwolf/luci" "master"  #网站域名黑白名单配置 去广告
#UPDATE_PACKAGE "luci-app-alist" "sbwml/luci-app-alist" "master"   #alist
#UPDATE_PACKAGE "luci-app-eqosplus" "sirpdboy/sirpdboy-package" "main" "pkg"    #EQS网速控制
#UPDATE_PACKAGE "luci-app-advanced" "sirpdboy/sirpdboy-package" "main" "pkg"  #系统高级设置【自带文件管理功能】
UPDATE_PACKAGE "luci-app-poweroffdevice" "sirpdboy/sirpdboy-package" "main" "pkg"  #关机功能插件
UPDATE_PACKAGE "luci-app-netdata" "sirpdboy/sirpdboy-package" "main" "pkg"   #实时监控
UPDATE_PACKAGE "luci-app-fileassistant" "Lienol/openwrt-package" "main" "pkg"   #文件助手
UPDATE_PACKAGE "luci-app-autotimeset" "sirpdboy/luci-app-autotimeset" "master"  #定时关机插件
UPDATE_PACKAGE "gecoosac" "lwb1978/openwrt-gecoosac" "main"    #集客 AC OpenWRT 插件 2.1 版
UPDATE_PACKAGE "luci-app-tailscale" "asvow/luci-app-tailscale" "main"   #tailscale
UPDATE_PACKAGE "luci-app-wolplus" "VIKINGYFY/luci-app-wolplus" "main"   #网络唤醒

#科学插件
UPDATE_PACKAGE "luci-app-ssr-plus" "fw876/helloworld" "master"
UPDATE_PACKAGE "passwall-packages" "xiaorouji/openwrt-passwall-packages" "main"
UPDATE_PACKAGE "luci-app-passwall" "xiaorouji/openwrt-passwall" "main" "pkg"
#UPDATE_PACKAGE "luci-app-passwall" "xiaorouji/openwrt-passwall" "luci-smartdns-dev" "pkg"
UPDATE_PACKAGE "luci-app-passwall2" "xiaorouji/openwrt-passwall2" "main"
UPDATE_PACKAGE "luci-app-mihomo" "morytyann/OpenWrt-mihomo" "main" "pkg"
UPDATE_PACKAGE "luci-app-openclash" "vernesong/OpenClash" "dev" "pkg"

if [[ $WRT_BRANCH == *"23.05"* ]]; then
	UPDATE_PACKAGE "homeproxy" "VIKINGYFY/homeproxy" "main"
fi

#更新软件包版本
UPDATE_VERSION() {
	local PKG_NAME=$1
	local PKG_MARK=${2:-not}
	local PKG_FILES=$(find ./ ../feeds/packages/ -maxdepth 3 -type f -wholename "*/$PKG_NAME/Makefile")

	echo " "

	if [ -z "$PKG_FILES" ]; then
		echo "$PKG_NAME not found!"
		return
	fi

	echo "$PKG_NAME version update has started!"

	for PKG_FILE in $PKG_FILES; do
		local PKG_REPO=$(grep -Pho 'PKG_SOURCE_URL:=https://.*github.com/\K[^/]+/[^/]+(?=.*)' $PKG_FILE | head -n 1)
		local PKG_VER=$(curl -sL "https://api.github.com/repos/$PKG_REPO/releases" | jq -r "map(select(.prerelease|$PKG_MARK)) | first | .tag_name")
		local NEW_VER=$(echo $PKG_VER | sed "s/.*v//g; s/_/./g")
		local NEW_HASH=$(curl -sL "https://codeload.github.com/$PKG_REPO/tar.gz/$PKG_VER" | sha256sum | cut -b -64)
		local OLD_VER=$(grep -Po "PKG_VERSION:=\K.*" "$PKG_FILE")

		echo "$OLD_VER $PKG_VER $NEW_VER $NEW_HASH"

		if [[ $NEW_VER =~ ^[0-9].* ]] && dpkg --compare-versions "$OLD_VER" lt "$NEW_VER"; then
			sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$NEW_VER/g" "$PKG_FILE"
			sed -i "s/PKG_HASH:=.*/PKG_HASH:=$NEW_HASH/g" "$PKG_FILE"
			echo "$PKG_FILE version has been updated!"
		else
			echo "$PKG_FILE version is already the latest!"
		fi
	done
}

#UPDATE_VERSION "软件包名" "测试版，true，可选，默认为否"
#UPDATE_VERSION "sing-box" "true"
