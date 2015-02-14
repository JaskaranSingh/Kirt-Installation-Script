#####################################################################
#                "Welcome to Kirt installation script"	            #
#                                                                   #   		       
#      Author   :  Jaskaran Singh Lamba, lamba.jaskaran@gmail.com   #     	       
#      License  :  GNU General Public License                       #   		      
#      Copyright:  Copyright (c) 2013, Great Developers             #  		       
#                                                                   #  		       
#      created : 11-Feb-2015                                        #  		       
#      last update : 14-Feb-2015                                    #  		       
#      VERSION=0.1                                                  # 		       
#                                                                   #  		       
#####################################################################

read -p "Enter your system username:" username
read -sp "Enter your system password:" password

###################################
#                                 #
#   Checks Interent Connections	  # 
#                  				  #
###################################

check_internet() {
	clear
    echo ""
    echo "######################################################"
    echo "#                                                    #"
    echo "#    CHECKING---Internet Connection---               #"
    echo "#                                                    #"
    echo "######################################################"
    echo ""

	packet_loss=$(ping -c 5 -q 202.164.53.116 | grep -oP '\d+(?=% packet loss)')
	if [ $packet_loss -ge 50 ]; then

	    echo "::::::::::::SLOW or NO INTERNET CONNECTION:::::::::::::"
	    echo "Please check your connectivity and try again later."
	    exit
	else
	     echo "::::::::::::INTERNET IS WORKING PROPERLY::::::::::::"
	fi
}

#########################################
#                                       #
#    Function to install dependencies   # 
#                                       #
#########################################


check_apt() {
result=$(dpkg-query -W -f='${package}\n' "$1")
if  [ "$result" = "$1" ]; then
		echo "$1 already installed"
	else
		echo "$1 is not installed in your system"
		echo "Installing mysql-server library"
	    echo $password | sudo -S apt-get install -y $1
		sudo apt-get -f install
fi
}

#########################################
#                                       #
#      Function to install django    	# 
#                                       #
#########################################


Install_django() {
	result=$(python -c "import django; print(django.get_version())")

	if [[ $result == *"1.7"* ]]
	then
  		echo "Django already installed";
	else
	    echo "Django is not installed in your system"
        echo "Installing Django"
	    echo $password | sudo -S pip install Django==1.7
	fi
}

#########################################
#                                       #
#      Function to configure Kirt    	# 
#                                       #
#########################################

Configure_kirt() {
	cd
	git clone https://github.com/KamalKaur/kirt.git
	
	a=1 
    while [ $a -ne 2 ]
    do
    	read -p "Enter your mysql username:" db_user  
        read -sp "Enter your mysql password:" db_password
        echo ""

        RESULT=`mysql --user="$db_user" --password="$db_password"\
        --skip-column-names -e "SHOW DATABASES LIKE 'mysql'"`
        if [ $RESULT ]; then
            echo ""
            echo "Username and Password Matches"
            a=`expr $a + 1`
            break
                 
        else
            echo ""
            echo "Username and Password don't match"
            echo "re-enter the details"
            echo ""
        fi
    done

    mysqlbash_path='/usr/bin/mysql'                            	  
    mysqlbash="$mysqlbash_path --user=$db_user --password=$db_password -e" 
    $mysqlbash "create database kirt"

    cd
	cd kirt/kirt/
	sed -i 's/username\/path-to...\/Kirt/'$username'\/kirt/g' settings.py
	sed -i 's/<Database name>/kirt/g' settings.py
	sed -i 's/<MySql user name>/'$db_user'/g' settings.py
	sed -i 's/<MySql username Password>/'$db_password'/g' settings.py

	cd
	cd kirt/
	git update-index --assume-unchanged kirt/settings.py
	python manage.py migrate
	python manage.py createsuperuser
}

#########################################
#                                       #
#    Function to configure apache 		# 
#                                       #
#########################################
Configure_apache() {
	echo $password | sudo -S a2enmod wsgi
	cd /etc/apache2/
	echo $password | sudo -S sed -i 's/denied/granted/g' apache2.conf

	insert='Alias /static/ /home/'$username'/kirt/src/static/\
	<Directory /home/'$username'/kirt/src/static/>\
	Order deny,allow\
	Allow from all\
	</Directory>\
	\nWSGIScriptAlias /kirt /home/'$username'/kirt/kirt/wsgi.py\
	WSGIPythonPath /home/'$username'/kirt/\
	<Directory /home/'$username'/kirt/src/>\
	<Files wsgi.py>\
	Order allow,deny\
	Allow from all\
	</Files>\
	</Directory>'

	echo $password | sudo -S sed -i "169i $insert" apache2.conf
	echo $password | sudo -S service apache2 restart
}

############################################################
#                                        				   #
#   Main Function: Includes calls to all other functions   # 
#                     									   #
############################################################

main() {
	
	check_internet

	dep=(apache2 mysql-server python2.7 python-pip python-mysqldb git python-reportlab libapache2-mod-wsgi)

	for i in "${dep[@]}"
	do
		check_apt $i
	done

	Install_django

	Configure_kirt
	
	Configure_apache

	firefox localhost/kirt
}

main
