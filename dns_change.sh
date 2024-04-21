#!/usr/bin/bash
# Script used to change the /etc/resolv.conf file automatically for differente usages 
# usage cases :
# crypt for encrypted dns 
# vpn for vpn access
# dafult for basic / standard usage 

file_name=$(basename "$0")
dns_file_path="/etc" # default path of the resolv.conf file
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
				change_mode 2 
			;;

			*)
				change_mode 1
			;;
		esac
	fi
	exit $SUCCESS
					
}


change_mode(){
	echo "Verify if $dns_base_file is immutable..."
	attributes=$(lsattr "$dns_base_file")
	if ! [[ attributes == *"i"* ]] && [ "$1" -eq 0 ]
	then	
		echo "changing DNS configuration to encrypted mode..."
		sudo echo -e "\
			nameserver ::1\n
			nameserver 127.0.0.1\n
			options trust-ad\n" > dns_base_file 
		sudo chattr +i $dns_base_file
		reload_configs 1
		echo "Done, enjoy encrypted DNS :)"

	elif ! [[ attributes == *"i"* ]] && [ "$1" -ne  0 ]
		if [ "$1" -eq 1 ]
		then 
			echo "Changing DNS configuration to standard mode..."
			sudo echo -e "\
				nameserver 9.9.9.9\n
				nameserver 1.1.1.1\n
			" > dns_base_file
			sudo chattr +i dns_base_file
			reload_configs 2
			echo "Done!"	

		else
			echo "Changing DNS configuration to VPN mode..."
			sudo echo -e " " > dns_base_file 
			reload_configs 2
		fi
	elif [[ attributes == *"i"* ]] && [ "$1" -ne  0 ]
		echo "$dns_base_file has chattr +i set changing..."
		sudo chattr -i dns_base_file
		if [ "$1" -eq 1 ]
		then 
			echo "Changing DNS configuration to standard mode..."
			sudo echo -e "\
				nameserver 9.9.9.9\n
				nameserver 1.1.1.1\n
			" > dns_base_file
			sudo chattr +i dns_base_file
			reload_configs 2
			echo "Done!"	

		else
			echo "Changing DNS configuration to VPN mode..."
			sudo echo -e " " > dns_base_file 
			reload_configs 2
		fi
	else
		echo "changing DNS configuration to encrypted mode..."
		sudo echo -e "\
			nameserver ::1\n
			nameserver 127.0.0.1\n
			options trust-ad\n" > dns_base_file 
		sudo chattr +i $dns_base_file
		reload_configs 1
		echo "Done, enjoy encrypted DNS :)"
	
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

change_file $1

