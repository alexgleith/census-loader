#!/usr/bin/env bash

# -------------------------------
# STEP 1 - install stuff
# -------------------------------

# try to silence annoying message about not having a UI
export DEBIAN_FRONTEND=noninteractive

# update Ubuntu
sudo apt-get update -y
# sudo apt-get upgrade -y

# get code
sudo git clone https://github.com/minus34/census-loader.git ~/git/census-loader/

# copy Postgres dump files to server
#cd ~/git/census-loader/data
sudo wget --quiet http://minus34.com/opendata/census-2016/census_2016_data.dmp > ~/git/census-loader/data/data.dmp
sudo wget --quiet http://minus34.com/opendata/census-2016/census_2016_web.dmp > ~/git/census-loader/data/web.dmp

# install Postgres
sudo add-apt-repository -y "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update -y
sudo apt-get install -y postgresql-9.6
sudo apt-get install -y postgresql-9.6-postgis-2.3 postgresql-contrib-9.6
sudo apt-get install -y postgis

# install python modules
sudo apt-get install -y python3-setuptools
sudo easy_install3 pip
sudo pip3.5 install flask
sudo pip3.5 install flask-compress
sudo pip3.5 install psycopg2

# install gunicorn
sudo apt-get install -y gunicorn


# ----------------------------------------------
# STEP 2 - restore data to Postgres
# ----------------------------------------------

# create user and database
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'password';"
#sudo -u postgres createuser -P censususer
sudo -u postgres createdb geo
#sudo -u postgres psql -c "GRANT postgres TO censususer; " geo
sudo -u postgres psql -c "CREATE EXTENSION adminpack;CREATE EXTENSION postgis;" geo

# import into database
sudo pg_restore -Fc -d geo -p 5432 -U postgres -h localhost ~/git/census-loader/data/data.dmp
#sudo pg_restore -Fc -d geo -p 5432 -U postgres ~/git/census-loader/data/census_2016_bdys.dmp  # don't need this one
sudo pg_restore -Fc -d geo -p 5432 -U postgres -h localhost ~/git/census-loader/data/web.dmp

# test data loaded ok
sudo -u postgres psql -c "SELECT Count(*) FROM census_2016_data.ste_t28b; " geo
sudo -u postgres psql -c "SELECT Count(*) FROM census_2016_web.ste; " geo




## set autovacuum off (need to change this to use sed to automate it)
#sudo vim /etc/postgresql/9.6/main/postgresql.conf



## restart postgres - if needed
#sudo service postgresql restart

## look at log files - if needed
#vim /var/log/postgresql/postgresql-9.6-main.log

## it screwed up - turf the schema and try again
#sudo -u postgres psql -c "DROP SCHEMA census_2016_web CASCADE;" geo
#sudo -u postgres psql -c "SELECT PostGIS_full_version();" geo




# -------------------------------
# STEP 3 - run this thing
# -------------------------------

## run the app
#sudo python3 ~/git/census-loader/deploy/web/server.py
#sudo gunicorn -w 4 -b 0.0.0.0:80 server:app
