#!/bin/bash
# Last Modified On: 24.05.2021
# Version : 1.0
# Description :
# Program Postapp oferuje :
# - wysyłanie wiadomości e-mail wraz z zalącznikami
# - wyświetlanie skrzynki odbiorczej
# - oblsugę książki adresowej
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)
adres=""
temat=""
fil=""
zal=""
persons=`cat adrr.csv | tail -n 1 | cut -d, -f1`   # zmienna definiująca indeks ostatniej osoby w książce adresowej
booklist=""
cho=0
choice=""
help() {
	zenity --text-info --title "Pomoc" --height 800 --width 800 < help.txt
}

version()
{
	zenity --info --width 350 --title "O programie" --text "Postapp wersja 0.6
	Stworzone przez : Wiktor Kawka 184417"
}
function listbook()
{
	mapfile -t array < adrr.csv     # zawartosc pliku csv kopiujemy do tablicy, aby móc wybrać konkretną osobę
	choice=`zenity --list --column=Menu "${array[@]}" --height 420 --width 540`
	cho=`echo $choice | cut -d, -f1`
}
function adr()
{
	local tempadr=`zenity --entry --width 350 --title "Adres" --text "Wpisz adres e-mail odbiorcy"`
	if [[ $tempadr =~ ^[0-9a-zA-Z]+(\.[0-9a-zA-Z]+)*@([a-z0-9]+\.)+[a-z]{2,}$ ]]; then    # walidacja adresu e-mail
	       adres=$adres" $tempadr"
		   zenity --info --width 350 --title "Operacja powiodla sie" --text "Dodawanie adresu e-mail powiodlo sie!"
        else
 		zenity --error --text "Niepoprawny adres e-mail"
	fi		
}
function sub()
{
	temat=`zenity --entry --width 350 --title "Temat" --text "Wpisz temat wiadomosci"`
	zenity --info --width 350 --title "Operacja powiodla sie" --text "Dodawanie tematu wiadomosci powiodlo sie!"
}
function txtfile()
{
	cd testmail
	fil=`zenity --file-selection --title "Plik z wiadomoscia" --file-filter='TXT files (txt) | *.txt'`  #filtr typu pliku
	cd ..
}
function writemsg()
{
	zenity --text-info --width 800 --height 800 --editable --title "Wpisz wiadomosc" > wiad.txt   #wpisanie wiadomosci do pliku .txt
	fil=wiad.txt
}
function att()
{
	local zalo=`zenity --file-selection`
	zal=$zal" -A $zalo"
	zenity --info --width 350 --title "Operacja powiodla sie" --text "Dodawanie zalacznika powiodlo sie!"
}
function send()
{
	if [ -z "${adres}" ]; then
		zenity --error --width 350 --text "Nie mozna wyslac wiadomosci bez ani jednego adresu!"   # walidowanie poprawności żądania
		return                                                                                    # wysłania wiadomości e-mail
	fi
	if [ -z "${temat}" ]; then
		zenity --error --width 350 --text "Nie mozna wyslac wiadomosci bez tematu!"
		return
	fi
	if [ -z "${fil}" ]; then
		zenity --error --width 350 --text "Nie mozna wyslac wiadomosci bez tresci!"
		return
	fi
	mail -s "$temat" $zal $adres < $fil
	zenity --info --width 350 --title "Operacja powiodla sie" --text "Wyslanie wiadomosci e-mail powiodlo sie!"
	temat=""
	zal=""
	adres=""
	fil=""
}
function viewmail()
{
	local pth=`pwd`
	local lng=0
	cd ..
	cd Maildir/new/
	local mviev=`zenity --file-selection --file-filter='Mail files | *.wiktor-VirtualBox'`  #filtr rypu wiadomośći
	if [ -z "${mviev}" ]; then
		cd $pth
		return
	fi
	while [[ $? -eq 0 ]]; do
		touch temp.txt
		tail +8 $mviev > temp.txt   # wyswietlenie wiadomosci z pliku bez poczatkowych headerow (dlatego 8 linia)
		zenity --text-info --width 800 --height 800 < temp.txt
		rm temp.txt
		mviev=`zenity --file-selection`
	done
	cd $pth
}
function end()
{
	zenity --question --width 350 --title "Wyjscie z programu" --text "Czy na pewno chcesz wyjsc z programu?"
	case $? in
		1) opcja=0;;
	esac
}
function kadr()
{
	listbook
	local tempm=`echo $choice | cut -d, -f3`  #doklejnenie adresu email do wysyłki
	adres=$adres" $tempm"
}
function addper()
{
	persons=`cat adrr.csv | tail -n 1 | cut -d, -f1`  #ustalenie ostatniego indeksu osoby w książce
	zenity --forms --title "Dodaj nowy kontakt" \
	 --separator="," \
	 --add-entry="Nazwa" \
	 --add-entry="Adres e-mail" > adtemp.txt    # pola formularza
	 local newn=`cat adtemp.txt | cut -d, -f1`
	 local newa=`cat adtemp.txt | cut -d, -f2`
	 if [ -z "${newn}" ]; then
	 	zenity --error --width 350 --text "Nazwa nie moze byc pusta!" #walidacja
		 rm adtemp.txt
		 return
	 fi
	if [[ $newa =~ ^[0-9a-zA-Z]+(\.[0-9a-zA-Z]+)*@([a-z0-9]+\.)+[a-z]{2,}$ ]]; then   #walidacja
		persons=$((persons+1))
		local record=$persons,$newn,$newa
		echo $record >> adrr.csv
		else
 		zenity --error --width 350 --text "Niepoprawny adres e-mail"
	fi
	 rm adtemp.txt
}
function rmper()
{
	listbook
	if [ ! -z "${choice}" ]; then
		zenity --question --width 350 --title "Usun kontakt" --text "Czy na pewno chcesz usunac ten kontakt?"
		case $? in
			0) sed -i "/$cho/d" ./adrr.csv;   #usuniecie rekordu z pliku .csv
		esac
	fi
}
while getopts hv OPT; do
	case $OPT in
		h) help;;
		v) version;;
		*) echo "Nieznana opcja. Dozwolone opcje: h, v"; exit;;
	esac
done

opcja=0
while [[ $opcja -ne 13 ]]; do
	menu=("1. Adres odbiorcy: $adres" "2.Dodaj adresata z ksiazki adresowej" "3. Temat wiadomosci: $temat" 
	"4.Wybierz plik tekstowy z wiadomoscia" "5.Kliknij tutaj, aby wpisac tresc wiadomosci"
	 "6.Kliknij tutaj, aby dodac zalacznik" "7.Wyslij wiadomosc" "8.Wyswietl skrzynke odbiorcza" 
	 "9.Dodaj kontakt do ksiazki adresowej" "10.Usun kontakt z ksiazki adresowej" "11. Wyczysc pasek adresatow"
	 "12. Wyczysc zalaczone pliki" "13. Zakoncz program")
	cmd=`zenity --list --column=Menu "${menu[@]}" --height 420 --width 540`
	opcja=`echo $cmd | cut -d. -f1`
	case $opcja in
		1) adr;;
		2) kadr;;
	    3) sub;;
	    4) txtfile;;
		5) writemsg;;
		6) att;;
		7) send;;
		8) viewmail;;
		9) addper;;
		10) rmper;;
		11) adres="";;
		12) zal="";;
		13) end;;
		*) zenity --error --width 350 --title "Niepoprawna komenda" --text "Niepoprawna komenda"; exit;;
	esac
done
