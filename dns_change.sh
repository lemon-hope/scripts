#!/usr/bin/bash
# Script used to change the /etc/resolv.conf file automatically for differente usages 
# usage cases :
# crypt for encrypted dns 
# vpn for vpn access
# dafult for basic / standard usage 

file_name=$(basename "$0")
dns_file_path="/etc" # default path of the resolv.conf file
dns_files_array=("resolv.conf.crypt" "resolv.conf.base" "resolv.conf.vpn")# each file has different configuration for the dns server  
dns_base_file="$dns_file_path/resolv.conf"
SUCCESS=0
ERROR=1



change_file (){
	if [ -z $1 ]
	then
		usage
		exit ERROR
	else
		case $1 in
			crypt)
				change_mode 0 
			;;

			vpn)
				change_mode 1
			;;

			*)
				change_mode 2
			;;
		esac
	fi
	exit $SUCCESS
					
}

crypt_mode(){
	crypt_dns_file="$dns_file_path/$dns_file_array[0]"  
	echo "Verifying if crypt DNS file exist..."
	if [ -f $crypt_dns_file ]
	then
		"crypt dns file exists => changing configuration..."
		# remove the chattr attribute and
		# switch the resolv.conf content by the resolv.conf.crypt content
		sudo cp -f $crypt_dns_file $dns_base_file
		sudo chattr +i $dns_base_file
		reload_configs 1
		echo "Done, enjoy encrypted DNS :)"
	else
		"echo crypt DNS file does not exist terminating..."
		exit $ERROR
	fi
		
}

change_mode(){
	new_dns_file="$dns_file_path/$dns_file_array["$1"]"
	echo "Verifying if $1 configuration exist..."
	if [ -f $new_dns_file ]
	then
		echo "Verify if $dns_base_file is immutable..."
		attributes=$(lsattr "$dns_base_file")
		if [[ attributes == *"i"* ]]
		then
			echo "file has chattr +i set, changing..."
			sudo chattr -i "$dns_base_file"
			sudo cp -f $new_dns_file $dns_base_file
			reload_configs 2
			echo "Done! ready to use"
		else
			echo "file has no chattr +i set"
			sudo cp -f $new_dns_file $dns_base_file
			reload_configs 2
			echo "Done! ready to use"
		fi
	else
		echo "$new_dns_file configuration file does not exist terminating..."
		exit $ERROR
	fi
	

}



usage(){
	echo "usage : $file_name [MODE]"
	echo -e "MODE\n \
		crypt : for encrypted DNS configuration with stubby and dnsmasq\n \
		vpn   : for fresh configuration file for vpn usage\n \
		std   : for a standadr DNS configuration file\n "
}

reload_configs(){

	echo "reloading configs..."
	case $1 in
		1)
			sudo systemctl restart NetworkManager \
			&& sudo systemctl restart stubby.service dnsmasq.service
		;;
		*)
			sudo systemctl stop --now stubby.service \
			&& sudo systemctl stop --now dnsmasq.service \
			&& sudo systemctl restart NetworkManager
		;;
}


