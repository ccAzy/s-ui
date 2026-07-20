#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

function LOGD() {
    echo -e "${yellow}[DEG] $* ${plain}"
}

function LOGE() {
    echo -e "${red}[ERR] $* ${plain}"
}

function LOGI() {
    echo -e "${green}[INF] $* ${plain}"
}

[[ $EUID -ne 0 ]] && LOGE "ERROR: You must be root to run this script! \n" && exit 1

if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo "Failed to check the system OS, please contact the author!" >&2
    exit 1
fi

echo "The OS release is: $release"

# Detect the init system (systemd vs OpenRC used by Alpine)
if [[ "$release" == "alpine" ]]; then
    init_system="openrc"
elif command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]; then
    init_system="systemd"
elif command -v rc-service >/dev/null 2>&1; then
    init_system="openrc"
else
    init_system="systemd"
fi

# Service wrappers so the menu works on both systemd and OpenRC (Alpine).
svc_start()   { if [[ "${init_system}" == "openrc" ]]; then rc-service "$1" start; else systemctl start "$1"; fi; }
svc_stop()    { if [[ "${init_system}" == "openrc" ]]; then rc-service "$1" stop; else systemctl stop "$1"; fi; }
svc_restart() { if [[ "${init_system}" == "openrc" ]]; then rc-service "$1" restart; else systemctl restart "$1"; fi; }
svc_status()  { if [[ "${init_system}" == "openrc" ]]; then rc-service "$1" status; else systemctl status "$1" -l; fi; }
svc_enable()  { if [[ "${init_system}" == "openrc" ]]; then rc-update add "$1" default; else systemctl enable "$1"; fi; }
svc_disable() { if [[ "${init_system}" == "openrc" ]]; then rc-update del "$1" default; else systemctl disable "$1"; fi; }
svc_log()     { if [[ "${init_system}" == "openrc" ]]; then tail -n 200 -f /var/log/s-ui.log; else journalctl -u "$1".service -e --no-pager -f; fi; }

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [Default$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "Restart the ${1} service" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}Press enter to return to the main menu: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/alireza0/s-ui/main/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    confirm "This function will forcefully reinstall the latest version, and the data will not be lost. Do you want to continue?" "n"
    if [[ $? != 0 ]]; then
        LOGE "Cancelled"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi
    bash <(curl -Ls https://raw.githubusercontent.com/alireza0/s-ui/main/install.sh)
    if [[ $? == 0 ]]; then
        LOGI "Update is complete, Panel has automatically restarted "
        exit 0
    fi
}

custom_version() {
    echo "Enter the panel version (like 0.0.1):"
    read panel_version

    if [ -z "$panel_version" ]; then
        echo "Panel version cannot be empty. Exiting."
    exit 1
    fi

    download_link="https://raw.githubusercontent.com/alireza0/s-ui/master/install.sh"

    install_command="bash <(curl -Ls $download_link) $panel_version"

    echo "Downloading and installing panel version $panel_version..."
    eval $install_command
}

uninstall() {
    confirm "Are you sure you want to uninstall the panel?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    if [[ "${init_system}" == "openrc" ]]; then
        rc-service s-ui stop
        rc-update del s-ui default
        rm /etc/init.d/s-ui -f
    else
        systemctl stop s-ui
        systemctl disable s-ui
        rm /etc/systemd/system/s-ui.service -f
        systemctl daemon-reload
        systemctl reset-failed
    fi
    rm /etc/s-ui/ -rf
    rm /usr/local/s-ui/ -rf

    echo ""
    echo -e "Uninstalled Successfully, If you want to remove this script, then after exiting the script run ${green}rm /usr/local/s-ui -f${plain} to delete it."
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

reset_admin() {
    echo "It is not recommended to set admin's credentials to default!"
    confirm "Are you sure you want to reset admin's credentials to default ?" "n"
    if [[ $? == 0 ]]; then
        /usr/local/s-ui/sui admin -reset
    fi
    before_show_menu
}

set_admin() {
    echo "It is not recommended to set admin's credentials to a complex text."
    read -p "Please set up your username:" config_account
    read -p "Please set up your password:" config_password
    /usr/local/s-ui/sui admin -username ${config_account} -password ${config_password}
    before_show_menu
}

view_admin() {
    /usr/local/s-ui/sui admin -show
    before_show_menu
}

reset_setting() {
    confirm "Are you sure you want to reset settings to default ?" "n"
    if [[ $? == 0 ]]; then
        /usr/local/s-ui/sui setting -reset
    fi
    before_show_menu
}

set_setting() {
    echo -e "Enter the ${yellow}panel port${plain} (leave blank for existing/default value):"
    read config_port
    echo -e "Enter the ${yellow}panel path${plain} (leave blank for existing/default value):"
    read config_path

    echo -e "Enter the ${yellow}subscription port${plain} (leave blank for existing/default value):"
    read config_subPort
    echo -e "Enter the ${yellow}subscription path${plain} (leave blank for existing/default value):" 
    read config_subPath

    echo -e "${yellow}Initializing, please wait...${plain}"
    params=""
    [ -z "$config_port" ] || params="$params -port $config_port"
    [ -z "$config_path" ] || params="$params -path $config_path"
    [ -z "$config_subPort" ] || params="$params -subPort $config_subPort"
    [ -z "$config_subPath" ] || params="$params -subPath $config_subPath"
    /usr/local/s-ui/sui setting ${params}
    before_show_menu
}

view_setting() {
    /usr/local/s-ui/sui setting -show
    view_uri
    before_show_menu
}

view_uri() {
    info=$(/usr/local/s-ui/sui uri)
    if [[ $? != 0 ]]; then
        LOGE "Get current uri error"
        before_show_menu
    fi
    LOGI "You may access the Panel with following URL(s):"
    echo -e "${green}${info}${plain}"
}

start() {
    check_status $1
    if [[ $? == 0 ]]; then
        echo ""
        LOGI -e "${1} is running, No need to start again, If you need to restart, please select restart"
    else
        svc_start $1
        sleep 2
        check_status $1
        if [[ $? == 0 ]]; then
            LOGI "${1} Started Successfully"
        else
            LOGE "Failed to start ${1}, Probably because it takes longer than two seconds to start, Please check the log information later"
        fi
    fi

    if [[ $# == 1 ]]; then
        before_show_menu
    fi
}

stop() {
    check_status $1
    if [[ $? == 1 ]]; then
        echo ""
        LOGI "${1} stopped, No need to stop again!"
    else
        svc_stop $1
        sleep 2
        check_status
        if [[ $? == 1 ]]; then
            LOGI "${1} stopped successfully"
        else
            LOGE "Failed to stop ${1}, Probably because the stop time exceeds two seconds, Please check the log information later"
        fi
    fi

    if [[ $# == 1 ]]; then
        before_show_menu
    fi
}

restart() {
    svc_restart $1
    sleep 2
    check_status $1
    if [[ $? == 0 ]]; then
        LOGI "${1} Restarted successfully"
    else
        LOGE "Failed to restart ${1}, Probably because it takes longer than two seconds to start, Please check the log information later"
    fi
    if [[ $# == 1 ]]; then
        before_show_menu
    fi
}

status() {
    svc_status s-ui
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    svc_enable $1
    if [[ $? == 0 ]]; then
        LOGI "Set ${1} to boot automatically on startup successfully"
    else
        LOGE "Failed to set ${1} Autostart"
    fi

    if [[ $# == 1 ]]; then
        before_show_menu
    fi
}

disable() {
    svc_disable $1
    if [[ $? == 0 ]]; then
        LOGI "Autostart ${1} Cancelled successfully"
    else
        LOGE "Failed to cancel ${1} autostart"
    fi

    if [[ $# == 1 ]]; then
        before_show_menu
    fi
}

show_log() {
    svc_log $1
    if [[ $# == 1 ]]; then
        before_show_menu
    fi
}

update_shell() {
    wget -O /usr/bin/s-ui -N --no-check-certificate https://github.com/alireza0/s-ui/raw/main/s-ui.sh
    if [[ $? != 0 ]]; then
        echo ""
        LOGE "Failed to download script, Please check whether the machine can connect Github"
        before_show_menu
    else
        chmod +x /usr/bin/s-ui
        LOGI "Upgrade script succeeded, Please rerun the script" && exit 0
    fi
}

check_status() {
    if [[ "${init_system}" == "openrc" ]]; then
        if [[ ! -f "/etc/init.d/$1" ]]; then
            return 2
        fi
        if rc-service "$1" status >/dev/null 2>&1; then
            return 0
        else
            return 1
        fi
    fi
    if [[ ! -f "/etc/systemd/system/$1.service" ]]; then
        return 2
    fi
    temp=$(systemctl status "$1" | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

check_enabled() {
    if [[ "${init_system}" == "openrc" ]]; then
        if rc-update show default 2>/dev/null | grep -qw "$1"; then
            return 0
        else
            return 1
        fi
    fi
    temp=$(systemctl is-enabled $1)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1
    fi
}

check_uninstall() {
    check_status s-ui
    if [[ $? != 2 ]]; then
        echo ""
        LOGE "Panel is already installed, Please do not reinstall"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status s-ui
    if [[ $? == 2 ]]; then
        echo ""
        LOGE "Please install the panel first"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status $1
    case $? in
    0)
        echo -e "${1} state: ${green}Running${plain}"
        show_enable_status $1
        ;;
    1)
        echo -e "${1} state: ${yellow}Not Running${plain}"
        show_enable_status $1
        ;;
    2)
        echo -e "${1} state: ${red}Not Installed${plain}"
        ;;
    esac
}

show_enable_status() {
    check_enabled $1
    if [[ $? == 0 ]]; then
        echo -e "Start ${1} automatically: ${green}Yes${plain}"
    else
        echo -e "Start ${1} automatically: ${red}No${plain}"
    fi
}

check_s-ui_status() {
    count=$(ps -ef | grep "sui" | grep -v "grep" | wc -l)
    if [[ count -ne 0 ]]; then
        return 0
    else
        return 1
    fi
}

show_s-ui_status() {
    check_s-ui_status
    if [[ $? == 0 ]]; then
        echo -e "s-ui state: ${green}Running${plain}"
    else
        echo -e "s-ui state: ${red}Not Running${plain}"
    fi
}

bbr_menu() {
    echo -e "${green}\t1.${plain} Enable BBR"
    echo -e "${green}\t2.${plain} Disable BBR"
    echo -e "${green}\t0.${plain} Back to Main Menu"
    read -p "Choose an option: " choice
    case "$choice" in
    0)
        show_menu
        ;;
    1)
        enable_bbr
        ;;
    2)
        disable_bbr
        ;;
    *) echo "Invalid choice" ;;
    esac
}

disable_bbr() {
    if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.d/99-ygvpn-extreme.conf 2>/dev/null && \
       ! grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.d/99-ygvpn-extreme.conf 2>/dev/null && \
       ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf 2>/dev/null || \
       ! grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf 2>/dev/null; then
        echo -e "${yellow}BBR is not currently enabled.${plain}"
        exit 0
    fi
    # Remove from ygvpn-extreme.conf
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.d/99-ygvpn-extreme.conf 2>/dev/null
    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.d/99-ygvpn-extreme.conf 2>/dev/null
    # Remove from sysctl.conf
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf 2>/dev/null
    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf 2>/dev/null
    sysctl -w net.core.default_qdisc=pfifo_fast
    sysctl -w net.ipv4.tcp_congestion_control=cubic
    if [[ $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}') == "cubic" ]]; then
        echo -e "${green}BBR has been replaced with CUBIC successfully.${plain}"
    else
        echo -e "${red}Failed to replace BBR with CUBIC. Please check your system configuration.${plain}"
    fi
}

enable_bbr() {
    if grep -q "net.core.default_qdisc=fq" /etc/sysctl.d/99-ygvpn-extreme.conf 2>/dev/null && grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.d/99-ygvpn-extreme.conf 2>/dev/null; then
        echo -e "${green}BBR is already enabled!${plain}"
        exit 0
    fi
    case "${release}" in
    ubuntu | debian | armbian)
        apt-get update && apt-get install -yqq --no-install-recommends ca-certificates
        ;;
    centos | almalinux | rocky | oracle)
        yum -y update && yum -y install ca-certificates
        ;;
    fedora)
        dnf -y update && dnf -y install ca-certificates
        ;;
    arch | manjaro | parch)
        pacman -Sy --noconfirm ca-certificates
        ;;
    alpine)
        apk update && apk add --no-cache ca-certificates
        ;;
    *)
        echo -e "${red}Unsupported operating system. Please check the script and install the necessary packages manually.${plain}\n"
        exit 1
        ;;
    esac
    # Write to ygvpn-extreme.conf for consistency with system optimization
    mkdir -p /etc/sysctl.d
    grep -q "net.core.default_qdisc" /etc/sysctl.d/99-ygvpn-extreme.conf 2>/dev/null || \
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.d/99-ygvpn-extreme.conf
    grep -q "net.ipv4.tcp_congestion_control" /etc/sysctl.d/99-ygvpn-extreme.conf 2>/dev/null || \
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.d/99-ygvpn-extreme.conf
    sed -i 's/net.core.default_qdisc.*/net.core.default_qdisc = fq/' /etc/sysctl.d/99-ygvpn-extreme.conf
    sed -i 's/net.ipv4.tcp_congestion_control.*/net.ipv4.tcp_congestion_control = bbr/' /etc/sysctl.d/99-ygvpn-extreme.conf
    # Also update sysctl.conf for backward compatibility
    sed -i 's/net.core.default_qdisc=.*/net.core.default_qdisc=fq/' /etc/sysctl.conf 2>/dev/null || \
        grep -q "net.core.default_qdisc" /etc/sysctl.conf 2>/dev/null || \
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    sed -i 's/net.ipv4.tcp_congestion_control=.*/net.ipv4.tcp_congestion_control=bbr/' /etc/sysctl.conf 2>/dev/null || \
        grep -q "net.ipv4.tcp_congestion_control" /etc/sysctl.conf 2>/dev/null || \
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
    if [[ $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}') == "bbr" ]]; then
        echo -e "${green}BBR has been enabled successfully.${plain}"
    else
        echo -e "${red}Failed to enable BBR. Please check your system configuration.${plain}"
    fi
}

install_acme() {
    cd ~
    LOGI "install acme..."
    curl https://get.acme.sh | sh
    if [ $? -ne 0 ]; then
        LOGE "install acme failed"
        return 1
    else
        LOGI "install acme succeed"
    fi
    return 0
}

ssl_cert_issue_main() {
    echo -e "${green}\t1.${plain} Get SSL"
    echo -e "${green}\t2.${plain} Revoke"
    echo -e "${green}\t3.${plain} Force Renew"
    echo -e "${green}\t4.${plain} Self-signed Certificate"
    read -p "Choose an option: " choice
    case "$choice" in
        1) ssl_cert_issue ;;
        2) 
            local domain=""
            read -p "Please enter your domain name to revoke the certificate: " domain
            ~/.acme.sh/acme.sh --revoke -d ${domain}
            LOGI "Certificate revoked"
            ;;
        3)
            local domain=""
            read -p "Please enter your domain name to forcefully renew an SSL certificate: " domain
            ~/.acme.sh/acme.sh --renew -d ${domain} --force ;;
        4)
            generate_self_signed_cert
            ;;
        *) echo "Invalid choice" ;;
    esac
}

ssl_cert_issue() {
    if ! command -v ~/.acme.sh/acme.sh &>/dev/null; then
        echo "acme.sh could not be found. we will install it"
        install_acme
        if [ $? -ne 0 ]; then
            LOGE "install acme failed, please check logs"
            exit 1
        fi
    fi
    case "${release}" in
    ubuntu | debian | armbian)
        apt update && apt install socat -y
        ;;
    centos | almalinux | rocky | oracle)
        yum -y update && yum -y install socat
        ;;
    fedora)
        dnf -y update && dnf -y install socat
        ;;
    arch | manjaro | parch)
        pacman -Sy --noconfirm socat
        ;;
    alpine)
        apk update && apk add --no-cache socat
        ;;
    *)
        echo -e "${red}Unsupported operating system. Please check the script and install the necessary packages manually.${plain}\n"
        exit 1
        ;;
    esac
    if [ $? -ne 0 ]; then
        LOGE "install socat failed, please check logs"
        exit 1
    else
        LOGI "install socat succeed..."
    fi

    local domain=""
    read -p "Please enter your domain name:" domain
    LOGD "your domain is:${domain},check it..."
    local currentCert=$(~/.acme.sh/acme.sh --list | tail -1 | awk '{print $1}')

    if [ ${currentCert} == ${domain} ]; then
        local certInfo=$(~/.acme.sh/acme.sh --list)
        LOGE "system already has certs here,can not issue again,current certs details:"
        LOGI "$certInfo"
        exit 1
    else
        LOGI "your domain is ready for issuing cert now..."
    fi

    certPath="/root/cert/${domain}"
    if [ ! -d "$certPath" ]; then
        mkdir -p "$certPath"
    else
        rm -rf "$certPath"
        mkdir -p "$certPath"
    fi

    local WebPort=80
    read -p "please choose which port do you use,default will be 80 port:" WebPort
    if [[ ${WebPort} -gt 65535 || ${WebPort} -lt 1 ]]; then
        LOGE "your input ${WebPort} is invalid,will use default port"
    fi
    LOGI "will use port:${WebPort} to issue certs,please make sure this port is open..."
    ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    ~/.acme.sh/acme.sh --issue -d ${domain} --standalone --httpport ${WebPort}
    if [ $? -ne 0 ]; then
        LOGE "issue certs failed,please check logs"
        rm -rf ~/.acme.sh/${domain}
        exit 1
    else
        LOGE "issue certs succeed,installing certs..."
    fi
    ~/.acme.sh/acme.sh --installcert -d ${domain} \
        --key-file /root/cert/${domain}/privkey.pem \
        --fullchain-file /root/cert/${domain}/fullchain.pem

    if [ $? -ne 0 ]; then
        LOGE "install certs failed,exit"
        rm -rf ~/.acme.sh/${domain}
        exit 1
    else
        LOGI "install certs succeed,enable auto renew..."
    fi

    ~/.acme.sh/acme.sh --upgrade --auto-upgrade
    if [ $? -ne 0 ]; then
        LOGE "auto renew failed, certs details:"
        ls -lah cert/*
        chmod 755 $certPath/*
        exit 1
    else
        LOGI "auto renew succeed, certs details:"
        ls -lah cert/*
        chmod 755 $certPath/*
    fi
}

ssl_cert_issue_CF() {
    echo -E ""
    LOGD "******Instructions for use******"
    echo "1) New certificate from Cloudflare"
    echo "2) Force renew existing Certificates"
    echo "3) Back to Menu"
    read -p "Enter your choice [1-3]: " choice

    certPath="/root/cert-CF"

    case $choice in
        1|2)
            force_flag=""
            if [ "$choice" -eq 2 ]; then
                force_flag="--force"
                echo "Forcing SSL certificate reissuance..."
            else
                echo "Starting SSL certificate issuance..."
            fi
            
            LOGD "******Instructions for use******"
            LOGI "This Acme script requires the following data:"
            LOGI "1.Cloudflare Registered e-mail"
            LOGI "2.Cloudflare Global API Key"
            LOGI "3.The domain name that has been resolved DNS to the current server by Cloudflare"
            LOGI "4.The script applies for a certificate. The default installation path is /root/cert "
            confirm "Confirmed?[y/n]" "y"
            if [ $? -eq 0 ]; then
                if ! command -v ~/.acme.sh/acme.sh &>/dev/null; then
                    echo "acme.sh could not be found. Installing..."
                    install_acme
                    if [ $? -ne 0 ]; then
                        LOGE "Install acme failed, please check logs"
                        exit 1
                    fi
                fi

                CF_Domain=""
                if [ ! -d "$certPath" ]; then
                    mkdir -p $certPath
                else
                    rm -rf $certPath
                    mkdir -p $certPath
                fi

                LOGD "Please set a domain name:"
                read -p "Input your domain here: " CF_Domain
                LOGD "Your domain name is set to: ${CF_Domain}"

                CF_GlobalKey=""
                CF_AccountEmail=""
                LOGD "Please set the API key:"
                read -p "Input your key here: " CF_GlobalKey
                LOGD "Your API key is: ${CF_GlobalKey}"

                LOGD "Please set up registered email:"
                read -p "Input your email here: " CF_AccountEmail
                LOGD "Your registered email address is: ${CF_AccountEmail}"

                ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
                if [ $? -ne 0 ]; then
                    LOGE "Default CA, Let's Encrypt failed, script exiting..."
                    exit 1
                fi

                export CF_Key="${CF_GlobalKey}"
                export CF_Email="${CF_AccountEmail}"

                ~/.acme.sh/acme.sh --issue --dns dns_cf -d ${CF_Domain} -d *.${CF_Domain} $force_flag --log
                if [ $? -ne 0 ]; then
                    LOGE "Certificate issuance failed, script exiting..."
                    exit 1
                else
                    LOGI "Certificate issued Successfully, Installing..."
                fi

                mkdir -p ${certPath}/${CF_Domain}
                if [ $? -ne 0 ]; then
                    LOGE "Failed to create directory: ${certPath}/${CF_Domain}"
                    exit 1
                fi

                ~/.acme.sh/acme.sh --installcert -d ${CF_Domain} -d *.${CF_Domain} \
                    --fullchain-file ${certPath}/${CF_Domain}/fullchain.pem \
                    --key-file ${certPath}/${CF_Domain}/privkey.pem

                if [ $? -ne 0 ]; then
                    LOGE "Certificate installation failed, script exiting..."
                    exit 1
                else
                    LOGI "Certificate installed Successfully, Turning on automatic updates..."
                fi

                ~/.acme.sh/acme.sh --upgrade --auto-upgrade
                if [ $? -ne 0 ]; then
                    LOGE "Auto update setup failed, script exiting..."
                    exit 1
                else
                    LOGI "The certificate is installed and auto-renewal is turned on."
                    ls -lah ${certPath}/${CF_Domain}
                    chmod 755 ${certPath}/${CF_Domain}
                fi
            fi
            show_menu
            ;;
        3)
            echo "Exiting..."
            show_menu
            ;;
        *)
            echo "Invalid choice, please select again."
            show_menu
            ;;
    esac
}

generate_self_signed_cert() {
    cert_dir="/etc/sing-box"
    mkdir -p "$cert_dir"
    LOGI "Choose certificate type:"
    echo -e "${green}\t1.${plain} Ed25519 (*recommended*)"
    echo -e "${green}\t2.${plain} RSA 2048"
    echo -e "${green}\t3.${plain} RSA 4096"
    echo -e "${green}\t4.${plain} ECDSA prime256v1"
    echo -e "${green}\t5.${plain} ECDSA secp384r1"
    read -p "Enter your choice [1-5, default 1]: " cert_type
    cert_type=${cert_type:-1}

    case "$cert_type" in
        1)
            algo="ed25519"
            key_opt="-newkey ed25519"
            ;;
        2)
            algo="rsa"
            key_opt="-newkey rsa:2048"
            ;;
        3)
            algo="rsa"
            key_opt="-newkey rsa:4096"
            ;;
        4)
            algo="ecdsa"
            key_opt="-newkey ec -pkeyopt ec_paramgen_curve:prime256v1"
            ;;
        5)
            algo="ecdsa"
            key_opt="-newkey ec -pkeyopt ec_paramgen_curve:secp384r1"
            ;;
        *)
            algo="ed25519"
            key_opt="-newkey ed25519"
            ;;
    esac

    LOGI "Generating self-signed certificate ($algo)..."
    sudo openssl req -x509 -nodes -days 3650 $key_opt \
        -keyout "${cert_dir}/self.key" \
        -out "${cert_dir}/self.crt" \
        -subj "/CN=myserver"
    if [[ $? -eq 0 ]]; then
        sudo chmod 600 "${cert_dir}/self."*
        LOGI "Self-signed certificate generated successfully!"
        LOGI "Certificate path: ${cert_dir}/self.crt"
        LOGI "Key path: ${cert_dir}/self.key"
    else
        LOGE "Failed to generate self-signed certificate."
    fi
    before_show_menu
}

show_usage() {
    echo -e "S-UI Control Menu Usage"
    echo -e "------------------------------------------"
    echo -e "SUBCOMMANDS:" 
    echo -e "s-ui              - Admin Management Script"
    echo -e "s-ui start        - Start s-ui"
    echo -e "s-ui stop         - Stop s-ui"
    echo -e "s-ui restart      - Restart s-ui"
    echo -e "s-ui status       - Current Status of s-ui"
    echo -e "s-ui enable       - Enable Autostart on OS Startup"
    echo -e "s-ui disable      - Disable Autostart on OS Startup"
    echo -e "s-ui log          - Check s-ui Logs"
    echo -e "s-ui update       - Update"
    echo -e "s-ui install      - Install"
    echo -e "s-ui uninstall    - Uninstall"
    echo -e "s-ui help         - Control Menu Usage"
    echo -e "------------------------------------------"
}

show_menu() {
  echo -e "
  ${green}S-UI Admin Management Script ${plain}
————————————————————————————————
  ${green}0.${plain} Exit
————————————————————————————————
  ${green}1.${plain} Install
  ${green}2.${plain} Update
  ${green}3.${plain} Custom Version
  ${green}4.${plain} Uninstall
————————————————————————————————
  ${green}5.${plain} Reset admin credentials to default
  ${green}6.${plain} Set admin credentials
  ${green}7.${plain} View admin credentials
————————————————————————————————
  ${green}8.${plain} Reset Panel Settings
  ${green}9.${plain} Set Panel settings
  ${green}10.${plain} View Panel Settings
————————————————————————————————
  ${green}11.${plain} S-UI Start
  ${green}12.${plain} S-UI Stop
  ${green}13.${plain} S-UI Restart
  ${green}14.${plain} S-UI Check State
  ${green}15.${plain} S-UI Check Logs
  ${green}16.${plain} S-UI Enable Autostart
  ${green}17.${plain} S-UI Disable Autostart
————————————————————————————————
  ${green}18.${plain} Enable or Disable BBR
  ${green}19.${plain} SSL Certificate Management
  ${green}20.${plain} Cloudflare SSL Certificate
————————————————————————————————
  ${green}21.${plain} ⚡ Apply System Optimization (YGVPN Extreme Tuning)
  ${green}22.${plain} 🏥 System Health Check
  ${green}23.${plain} 📊 View Optimization Status
  ${green}24.${plain} 🔄 Toggle Busy Polling
  ${green}25.${plain} 🌐 Enable/Disable IPv6
————————————————————————————————
 "
    show_status s-ui
    show_status s-ui\n    echo && read -p "Please enter your selection [0-25]: " num

    case "${num}" in
    0)
        exit 0
        ;;
    1)
        check_uninstall && install
        ;;
    2)
        check_install && update
        ;;
    3)
        check_install && custom_version
        ;;
    4)
        check_install && uninstall
        ;;
    5)
        check_install && reset_admin
        ;;
    6)
        check_install && set_admin
        ;;
    7)
        check_install && view_admin
        ;;
    8)
        check_install && reset_setting
        ;;
    9)
        check_install && set_setting
        ;;
    10)
        check_install && view_setting
        ;;
    11)
        check_install && start s-ui
        ;;
    12)
        check_install && stop s-ui
        ;;
    13)
        check_install && restart s-ui
        ;;
    14)
        check_install && status s-ui
        ;;
    15)
        check_install && show_log s-ui
        ;;
    16)
        check_install && enable s-ui
        ;;
    17)
        check_install && disable s-ui
        ;;
    18)
        bbr_menu
        ;;
    19)
        ssl_cert_issue_main
        ;;
    20)
    	ssl_cert_issue_CF
    	;;
    21)
    	check_install && ygvpn_extreme_optimize
    	;;
    22)
    	check_install && health_check
    	;;
    23)
    	check_install && view_optimize_status
    	;;
    24)
    	check_install && toggle_busy_polling
    	;;
    25)
    	check_install && toggle_ipv6
    	;;
    *)
    	LOGE "Please enter the correct number [0-25]"
    	;;
    esac
    }

# ── YGVPN Optimization Extensions ──

ygvpn_extreme_optimize() {
	echo -e "\n${green}╔════════════════════════════════════════╗${plain}"
	echo -e "${green}║   YGVPN Extreme System Optimization   ║${plain}"
	echo -e "${green}╚════════════════════════════════════════╝${plain}"
	echo ""
	echo "This will apply 80+ TCP/UDP/NIC/CPU/Kernel tuning parameters."
	echo ""
	echo -e "${yellow}Options:${plain}"
	echo -e "  ${green}1.${plain} Standard optimization (recommended)"
	echo -e "  ${green}2.${plain} Aggressive (RTO 50ms, rp_filter=2)"
	echo -e "  ${green}3.${plain} Aggressive + Busy Polling (CPU for lower latency)"
	echo -e "  ${green}0.${plain} Cancel"
	echo ""
	read -p "Choose an option [0-3]: " opt
	AGGRESSIVE_FLAG=""
	BUSY_POLL_FLAG=""
	case "${opt}" in
	1) ;;
	2) AGGRESSIVE_FLAG="--aggressive" ;;
	3) AGGRESSIVE_FLAG="--aggressive"; BUSY_POLL_FLAG="--busy-poll" ;;
	0|*) show_menu; return ;;
	esac

	[[ $EUID -ne 0 ]] && LOGE "Root required" && return 1
	SYSCTL_FILE="/etc/sysctl.d/99-ygvpn-extreme.conf"
	MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
	MEM_MB=$((MEM_KB / 1024))
	if [ "$MEM_MB" -ge 16384 ]; then
		TCP_MEM="131072 524288 2097152"; ADV_WIN=2
	elif [ "$MEM_MB" -ge 8192 ]; then
		TCP_MEM="65536 262144 1048576"; ADV_WIN=2
	elif [ "$MEM_MB" -ge 4096 ]; then
		TCP_MEM="32768 131072 524288"; ADV_WIN=1
	else
		TCP_MEM="16384 65536 262144"; ADV_WIN=1
	fi
	LOGI "RAM ${MEM_MB}MB, tcp_mem=${TCP_MEM}"

	cat > "$SYSCTL_FILE" << SYSCTLEOF
# YGVPN Extreme Network Optimization (applied by s-ui)
net.ipv4.tcp_mem = ${TCP_MEM}
net.ipv4.tcp_app_win = 0
net.ipv4.tcp_adv_win_scale = ${ADV_WIN}
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_autocorking = 1
net.ipv4.tcp_rfc1337 = 1
net.ipv4.tcp_thin_linear_timeouts = 1
net.ipv4.tcp_dsack = 1
net.ipv4.tcp_retrans_collapse = 0
net.ipv4.tcp_limit_output_bytes = 262144
net.ipv4.tcp_challenge_ack_limit = 2147483647
net.ipv4.tcp_fastopen_blackhole_timeout_sec = 0
net.ipv4.tcp_orphan_retries = 0
net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_syn_linear_timeouts = 2
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_comp_sack_nr = 3
net.ipv4.tcp_comp_sack_slack_ns = 5000
net.ipv4.tcp_comp_sack_rtt_percent = 10
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384
net.ipv4.conf.all.arp_ignore = 1
net.ipv4.conf.default.arp_ignore = 1
net.ipv4.conf.all.arp_announce = 2
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.all.arp_notify = 1
net.ipv4.conf.default.arp_notify = 1
net.ipv4.conf.all.log_martians = 0
net.ipv4.conf.default.log_martians = 0
vm.page-cluster = 0
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 50
vm.compaction_proactiveness = 0
kernel.timer_migration = 0
kernel.rcu_expedited = 1
net.core.optmem_max = 204800
net.netfilter.nf_conntrack_udp_timeout = 20
net.netfilter.nf_conntrack_udp_timeout_stream = 60
SYSCTLEOF

	sysctl -p "$SYSCTL_FILE" > /dev/null 2>&1 && LOGI "TCP/VM/Kernel params applied" || LOGE "Some sysctl params failed"

	if [ -n "$AGGRESSIVE_FLAG" ]; then
		cat >> "$SYSCTL_FILE" << 'AGGR'
net.ipv4.tcp_rto_min_us = 50000
net.ipv4.tcp_comp_sack_delay_ns = 50000
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
AGGR
		sysctl -w net.ipv4.tcp_rto_min_us=50000 > /dev/null 2>&1 || true
		sysctl -w net.ipv4.tcp_comp_sack_delay_ns=50000 > /dev/null 2>&1 || true
		sysctl -w net.ipv4.conf.all.rp_filter=2 > /dev/null 2>&1 || true
		LOGI "Aggressive: RTO 50ms, rp_filter=2"
	fi
	if [ -n "$BUSY_POLL_FLAG" ]; then
		cat >> "$SYSCTL_FILE" << 'BUSY'
net.core.busy_poll = 50
net.core.busy_read = 50
BUSY
		sysctl -w net.core.busy_poll=50 > /dev/null 2>&1 || true
		sysctl -w net.core.busy_read=50 > /dev/null 2>&1 || true
		LOGI "Busy polling 50us"
	fi

	if command -v ethtool &>/dev/null; then
		for eth in $(ls /sys/class/net 2>/dev/null | grep -vE "lo|docker|veth|br-|tun|sit0|wg"); do
			ethtool -C "$eth" adaptive-rx off 2>/dev/null || true
			ethtool -C "$eth" adaptive-tx off 2>/dev/null || true
			ethtool -K "$eth" sg on 2>/dev/null || true
			ethtool -K "$eth" tx-udp-segmentation on 2>/dev/null || true
			ethtool -K "$eth" ntuple on 2>/dev/null || true
			ethtool -A "$eth" autoneg on rx off tx off 2>/dev/null || true
		done
		CPUS=$(nproc); XPS=$(printf "%x" $(((1 << CPUS) - 1)))
		for eth in $(ls /sys/class/net 2>/dev/null | grep -vE "lo|docker|veth|br-|tun|sit0|wg"); do
			for xps_file in /sys/class/net/$eth/queues/tx-*/xps_cpus; do
				[ -f "$xps_file" ] && echo "$XPS" > "$xps_file" 2>/dev/null || true
			done
		done
		LOGI "Ethtool + XPS applied"
	else
		warn "ethtool not available"
	fi

	if pgrep -x sing-box > /dev/null 2>&1; then
		SB_PID=$(pgrep -x sing-box | head -1)
		chrt -f -p 99 "$SB_PID" 2>/dev/null && LOGI "Sing-box SCHED_FIFO 99" || true
	fi
	if [ -f /etc/systemd/system/sing-box.service ] && ! grep -q "LimitMEMLOCK=" /etc/systemd/system/sing-box.service; then
		sed -i '/^\[Service\]/a LimitMEMLOCK=infinity' /etc/systemd/system/sing-box.service
		systemctl daemon-reload 2>/dev/null || true
		LOGI "Sing-box LimitMEMLOCK=infinity"
	fi

	LOGI "✅ Optimization complete! Persisted to ${SYSCTL_FILE}"
	before_show_menu
}

health_check() {
	echo -e "\n${green}╔════════════════════════════════════════╗${plain}"
	echo -e "${green}║       System Health Check              ║${plain}"
	echo -e "${green}╚════════════════════════════════════════╝${plain}"
	echo ""
	echo -e "${green}── System ──${plain}"
	echo "  Hostname:    $(hostname)"
	echo "  Kernel:      $(uname -r)"
	echo "  OS:          $(uname -o 2>/dev/null || cat /etc/os-release 2>/dev/null | head -1 | grep -oP '"\K[^"]+' || echo 'N/A')"
	echo "  Uptime:      $(uptime -p 2>/dev/null || uptime | awk -F',' '{print $1}')"
	echo "  CPU:         $(nproc) cores / RAM: $(free -h | grep Mem | awk '{print $2}')"
	echo "  Load:        $(cat /proc/loadavg 2>/dev/null | awk '{print $1, $2, $3}' || echo 'N/A')"
	echo ""
	echo -e "${green}── Network ──${plain}"
	echo "  CC:          $(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk '{print $3}')"
	echo "  TFO:         $(sysctl net.ipv4.tcp_fastopen 2>/dev/null | awk '{print $3}')"
	dns_latency=$(timeout 3 ping -c 1 -W 2 223.5.5.5 2>&1 | grep -oP 'time=\K[0-9.]+')
	[ -n "$dns_latency" ] && echo "  DNS:         223.5.5.5 (${dns_latency}ms)" || echo -e "  DNS:         ${red}unreachable${plain}"
	echo ""
	echo -e "${green}── Disk ──${plain}"
	df -h / | tail -1 | awk '{print "  Root: " $2 " total, " $3 " used, " $4 " free (" $5 ")"}'
	echo ""
	echo -e "${green}── Conntrack ──${plain}"
	ct_c=$(cat /proc/sys/net/netfilter/nf_conntrack_count 2>/dev/null || echo 0)
	ct_m=$(cat /proc/sys/net/netfilter/nf_conntrack_max 2>/dev/null || echo 262144)
	echo "  ${ct_c} / ${ct_m} ($((ct_c * 100 / ct_m))%)"
	echo ""
	echo -e "${green}── Sing-box ──${plain}"
	if pgrep -x sing-box > /dev/null 2>&1; then
		SB_PID=$(pgrep -x sing-box | head -1)
		echo "  PID: ${SB_PID} | Sched: $(chrt -p ${SB_PID} 2>/dev/null | grep -oP 'policy \K.*' || echo 'default')"
	else
		echo -e "  Status: ${red}not running${plain}"
	fi
	if [ -f /etc/sysctl.d/99-ygvpn-extreme.conf ]; then
		echo "  Tuning: $(grep -c '= ' /etc/sysctl.d/99-ygvpn-extreme.conf) params applied"
	else
		echo -e "  Tuning: ${yellow}not applied${plain}"
	fi
	before_show_menu
}

view_optimize_status() {
	echo -e "\n${green}╔════════════════════════════════════════╗${plain}"
	echo -e "${green}║     Current Optimization Status         ║${plain}"
	echo -e "${green}╚════════════════════════════════════════╝${plain}"
	echo ""
	PARAMS=(
		"net.ipv4.tcp_congestion_control"
		"net.ipv4.tcp_fastopen"
		"net.ipv4.tcp_mem"
		"net.ipv4.tcp_limit_output_bytes"
		"net.ipv4.tcp_app_win"
		"net.ipv4.tcp_rfc1337"
		"net.ipv4.tcp_autocorking"
		"net.ipv4.tcp_no_metrics_save"
		"net.ipv4.tcp_challenge_ack_limit"
		"net.ipv4.tcp_syncookies"
		"net.ipv4.tcp_rto_min_us"
		"net.core.busy_poll"
		"vm.page-cluster"
		"vm.watermark_boost_factor"
		"vm.compaction_proactiveness"
		"kernel.timer_migration"
		"kernel.rcu_expedited"
	)
	for param in "${PARAMS[@]}"; do
		val=$(sysctl -n "$param" 2>/dev/null || echo "N/A")
		printf "  %-40s = %s\n" "$param" "$val"
	done
	before_show_menu
}

toggle_busy_polling() {
	echo -e "\n${green}── Toggle Busy Polling ──${plain}"
	CURRENT=$(sysctl -n net.core.busy_poll 2>/dev/null || echo 0)
	if [ "$CURRENT" != "0" ] && [ -n "$CURRENT" ]; then
		echo "  Current: Busy Polling = ${CURRENT}us (enabled)"
		echo -e "  ${green}1.${plain} Disable  |  ${green}0.${plain} Cancel"
		read -p "Choose: " opt
		if [ "$opt" = "1" ]; then
			sysctl -w net.core.busy_poll=0 net.core.busy_read=0 > /dev/null 2>&1
			sed -i '/busy_poll/d; /busy_read/d' /etc/sysctl.d/99-ygvpn-extreme.conf 2>/dev/null || true
			LOGI "Busy Polling disabled"
		fi
	else
		echo "  Current: disabled"
		echo -e "  ${green}1.${plain} Enable (50us)  |  ${green}0.${plain} Cancel"
		read -p "Choose: " opt
		if [ "$opt" = "1" ]; then
			sysctl -w net.core.busy_poll=50 net.core.busy_read=50 > /dev/null 2>&1
			echo -e "\n# Busy Polling\nnet.core.busy_poll = 50\nnet.core.busy_read = 50" >> /etc/sysctl.d/99-ygvpn-extreme.conf 2>/dev/null || true
			LOGI "Busy Polling enabled (50us)"
		fi
	fi
	before_show_menu
}

toggle_ipv6() {
	echo -e "\n${green}── Toggle IPv6 ──${plain}"
	CURRENT=$(sysctl -n net.ipv6.conf.all.disable_ipv6 2>/dev/null || echo 0)
	if [ "$CURRENT" = "1" ]; then
		echo "  Current: IPv6 disabled"
		echo -e "  ${green}1.${plain} Enable IPv6  |  ${green}0.${plain} Cancel"
		read -p "Choose: " opt
		if [ "$opt" = "1" ]; then
			rm -f /etc/sysctl.d/99-s-ui-disable-ipv6.conf
			sysctl -w net.ipv6.conf.all.disable_ipv6=0 net.ipv6.conf.default.disable_ipv6=0 > /dev/null 2>&1
			LOGI "IPv6 enabled"
		fi
	else
		echo "  Current: IPv6 enabled"
		echo -e "  ${green}1.${plain} Disable IPv6  |  ${green}0.${plain} Cancel"
		read -p "Choose: " opt
		if [ "$opt" = "1" ]; then
			echo -e "# s-ui: Disable IPv6\nnet.ipv6.conf.all.disable_ipv6 = 1\nnet.ipv6.conf.default.disable_ipv6 = 1" > /etc/sysctl.d/99-s-ui-disable-ipv6.conf
			sysctl -w net.ipv6.conf.all.disable_ipv6=1 net.ipv6.conf.default.disable_ipv6=1 > /dev/null 2>&1
			LOGI "IPv6 disabled"
		fi
	fi
	before_show_menu
}

if [[ $# > 0 ]]; then
    case $1 in
    "start")
        check_install 0 && start s-ui 0
        ;;
    "stop")
        check_install 0 && stop s-ui 0
        ;;
    "restart")
        check_install 0 && restart s-ui 0
        ;;
    "status")
        check_install 0 && status 0
        ;;
    "enable")
        check_install 0 && enable s-ui 0
        ;;
    "disable")
        check_install 0 && disable s-ui 0
        ;;
    "log")
        check_install 0 && show_log s-ui 0
        ;;
    "update")
        check_install 0 && update 0
        ;;
    "install")
        check_uninstall 0 && install 0
        ;;
    "uninstall")
        check_install 0 && uninstall 0
        ;;
    *) show_usage ;;
    esac
else
    show_menu
fi
