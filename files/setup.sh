#!/bin/bash

c=0
cd /media/ubuntu;
for file in $( ls );
do
  eval "var$c=/media/ubuntu/$file";
  c=$((c+1));
done

dir=$var0;

echo -n "Specify USB Directory [$var0]: ";
read -r input


if [ ! -z "$input" ]
then
eval "dir=$input";
fi

if [ ! -d "$dir" ]
then
echo "Invalid directory. Exiting!";
exit 1
fi

cd ~
killall -q -9 mwc

mkdir -p ~/bin
cd ~

cd $dir/
cp mwc* ~/bin

cd ~/bin

tar zxvf mwc-v2.3.0-linux-gnu.tgz
tar zxvf mwc-wallet-v2.0.2-linux-gnu.tgz
tar zxvf mwc713.tgz

rm -rf *.tgz

if grep --quiet PATH ~/.bashrc;
then
echo "already set path";
. ~/.bashrc
else
echo "export PATH=$PATH:/home/ubuntu/bin" >> ~/.bashrc;
export PATH=$PATH:/home/ubuntu/bin;
fi

mkdir -p ~/.mwc/floo
cd ~/.mwc/floo
mwc --floonet server config
perl -pi -e 's/run_tui = true/run_tui = false/g' ~/.mwc/floo/mwc-server.toml
echo "1337" > ~/.mwc/floo/.api_secret
rm -rf ~/.mwc/floo/chain_data
cp -pr $dir/node-files/chain_data ~/.mwc/floo
mwc --floonet &
sleep 1

echo -n "How many mwc-wallet instances? "
read -r MWCWALLETCOUNT;

i="1";

while [ $i -le $MWCWALLETCOUNT ]
do
  mkdir -p ~/mwcwallets/$i

  cd ~/mwcwallets/$i
  export MWC_PASSWORD="";

  echo -n "Would you like to recover mwc-wallet $i from a mnemonic? [y/n] ";
  read -r input;

if [ ! -z "$input" ]
then
  eval "$input=y";
fi

if [  "$input" == "y" ]
then
  echo -n "Input mwc-wallet $i mnemonic: ";
  read -r MNEMONIC;
  script -q -c 'mwc-wallet --floonet init -h -r' <<EOM
$MNEMONIC

EOM
else
  mwc-wallet --floonet init -h

EOM

fi

  unset MWC_PASSWORD;
  echo "1337" > .api_secret

  let "i=i+1";
done

cd ~

echo -n "How many mwc713 instances? "
read -r MWC713COUNT;

i="1";

while [ $i -le $MWC713COUNT ]
do
  mkdir -p ~/mwc713wallets/$i;

  tee -a ~/mwc713wallets/$i/config <<EOM
chain = "Floonet"
wallet713_data_path = "wallet713_data"
keybase_binary = "keybase"
mwcmq_domain = "mq.mwc.mw"
mwc_node_uri = "http://localhost:13413"
mwc_node_secret = "1337"
default_keybase_ttl = "24h"
EOM

  echo -n "Would you like to recover mwc713 $i from a mnemonic? [y/n] ";
  read -r input;

  if [ ! -z "$input" ]
  then
    eval "$input=y";
  fi

if [ "$input" == "y" ]
then


  echo -n "Input mwc713 wallet $i mnemonic: ";
  read -r MNEMONIC;

mwc713 --floonet -c ~/mwc713wallets/$i/config recover --mnemonic "$MNEMONIC" <<EOM

EOM
  else

mwc713 --floonet -c ~/mwc713wallets/$i/config init <<EOM


EOM
  fi
  let "i=i+1";
done


echo "Please remember to run # . ~/.bashrc";
