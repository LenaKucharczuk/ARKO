.data
spacja: .asciiz " "
input:	.asciiz "D:\kod.bmp"
err:	  .asciiz "Nie udalo sie zaladowac pliku!\n"
err2:   .asciiz "Zly rozmiar obrazka\n"
err3:   .asciiz "Zly format kodu\n"
Code:   .space 60 #tablica znakow kodu
Znak:   .asciiz "000000000\n" #.space 9 #tablica na 9 liczb: 1 lub 2 w zaleznosci od grubosci kresek/przerw w kolejnosci kreska,przerwa...kreska

Tablica_znakow: .asciiz "*0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%"
Tablica_kresek: .asciiz "121121211.111221211.211211112.112211112.212211111.111221112.211221111.112221111.111211212.211211211.112211211.211112112.112112112.212112111.111122112.211122111.112122111.111112212.211112211.112112211.111122211.211111122.112111122.212111121.111121122.211121121.112121121.111111222.211111221.112111221.111121221.221111112.122111112.222111111.121121112.221121111.122121111.121111212.221111211.122111211.121212111.121211121.121112121.111212121.\n"

header: .space 54
obrazek: .space 8000


# t0- deskryptor pliku, s2- wskaznik na headera, t8- rozmiar obrazka, t7- wysokość obrazka, t6- szerokosc obrazka

.text
.globl main

main:

# otwieram plik
	li $v0, 13		# 13 - otwarcie pliku
	la $a0, input   	# sciezka pliku
	li $a1, 0   		# read only
	li $a2, 0	    	# tryb ignorowany
	syscall
	move $t0, $v0           # zapisujemy deskryptor pliku w t0
	
# odczytuje z pliku:
	li $v0, 14 		# 14- odczyt z pliku
	move $a0, $t0 		# skopiuj deskryptor pliku do a0
	la $a1, header 		# addres buforu danych
	li $a2, 54 		# amount to read (bytes)
	syscall
	
	beq $zero, $v0, error	# sprawdzenie czy dane zostały wczytane
# sprawdzam plik
	la $t2, header		# lub move $t2, $a1
	ulw $t6, 18($t2)	# szerokosc
	ulw $t7, 22($t2) 	# wysokosc
	li $t4, 0x00000258	# 600 pikseli
	li $t3, 0x00000032		# 50 pikseli
	beq $t0, 0xffffffff, error 	#jesli sie nie powiodlo otwarcie, idz do error
	ulw $t8, 2($t2)  		#rozmiar
	bne $t4, $t6, error2 		# szerokosc obrazka ma byc 600 pikseli
	bne $t3, $t7, error2	 	# wysokosc obrazka ma byc 50 pikseli
	
# Zapis obrazka do pamieci
	li      $v0, 14                                                             
	move    $a0, $t0                                                    
	la      $a1, obrazek                                                
	move    $a2, $t8                                                    
	syscall  
	
# zczytuje
	la $t3, obrazek			# nasz obrazek w $t3
	addu $t3, $t3, 45000		# przesuwam na srodek wysokosci obrazka- 600*3*25
		
   przesun_do_paska:
	lb $t7, ($t3)                   # Wczytanie piksela
	beq $t7, 0, dalej 		# Gdy bajt czarny- wyjdz z petli
  addu $t3, $t3, 3		# Przesuwam na kolejny piksel
   b przesun_do_paska

   dalej:
   	li $t1, 1		# liczba pikseli przypadajacej na pasek waski
   badam_szerokosc_waskiego:
   	addu $t3, $t3, 3
   	lb $t7, ($t3)
   	bne $t7, 0, dalej2	# Jesli bajt juz nie jest czarny- caly pasek wczytany
   	addu $t1, $t1, 1		#zliczam szerokosc pikseli waskiego
   b badam_szerokosc_waskiego   
   dalej2:
	
   	li $t2, 1		# liczba pikseli szerokiej przerwy
   badam_szerokosc_szerokiego:
   	addu $t3, $t3, 3
   	lb $t7, ($t3)
   	beq $t7, 0, dalej3	# Jesli bajt czarny- cala przerwa wczytana
   	addu $t2, $t2, 1
   b badam_szerokosc_szerokiego
   	
   	dalej3:
   	  # przesuwam sie do 1 symbolu, za znak startu
   	mul $s5, $t1, 5		# pozostalo 5 waskich paskow   	
   	mul $t4, $t2, 2		# pozostaly 2 szerokie   	
   	addu $t4, $t4, $s5  	# liczba pikseli ktore pozostaly do konca znaku startu   	
   	mul $t4, $t4, 3 	# liczba bajtow do przesuniecia za start   	
   	addu $t3, $t3, $t4	# przesuwam wskaznik na obrazku za znak startu
   	   	
   	la $t9, Code		# ustawiam wskaznik na tablice Code
   	mul $t4, $t1, 3
   	addu $t3, $t3, 3
	
	li $a1, 0
######################################  	
   zaczynam_zczytywac_znak:
   	addu $t3, $t3, $t4 	# przesuwam wskaznik o waska przerwe miedzy kolejnymi znakami  	
   	la $t8, Znak		# ustawiam wskaznik na tablice Znak   	
   	la $t6, Tablica_znakow
   	la $t7, Tablica_kresek
   	li $s7, 0		# licznik kresek i przerw- jesli 9- wyjdz z petli
   	   	
   wczytaj_kreski_i_przerwy_znaku:
   	li $s6, 1 		# licznik szerokosci w pikselach
      kreska:
   	lb $s0, ($t3)
   	addu $t3, $t3, 3
   	bne $s0, 0, znak
   	addu $s6, $s6, 1	# inkrementuje liczbe pikseli kreski   	
      b kreska
   	
   	znak:
   	beq $s6, $t1, waski
   	szeroki:
   	li $s1, '2'
   	sb $s1, ($t8)
   	j dalej4		# omin waski
   	waski:
   	li $s1, '1'
   	sb $s1, ($t8)
   	dalej4:
   	addu $t8, $t8, 1	# przesuwam wskaznik na tablicy kresek i przerw
   	addu $s7, $s7, 1	# ++ do licznika kresek i przerw
   	li $s6, 0		# zeruje licznik szerokosci
   	beq $s7, 9, wczytany
   	
   	li $s6, 1
      przerwa:
   	lb $s0, ($t3)
   	addu $t3, $t3, 3
   	beq $s0, 0, znak2
   	addu $s6, $s6, 1 	
      b przerwa
   	
   	znak2:
   	beq $s6, $t1, waski2
   	szeroki2:
   	li $s1, '2'
   	sb $s1, ($t8)
   	j dalej5		# omin waski
   	waski2:
   	li $s1, '1'
   	sb $s1, ($t8)
   	   	
   	dalej5:
   	addu $t8, $t8, 1	# przesuwam wskaznik na tablicy kresek i przerw "Znak"
   	addu $s7, $s7, 1		# ++ do licznika kresek i przerw
   	 		
   	j wczytaj_kreski_i_przerwy_znaku
   	
   ######################	
   wczytany:	# dekoduje znak
   	mul $t4, $t1, 3	
   	   	  		  		
   	la $t8, Znak		# ponownie ustawiam wskaznik na poczatek tablicy Znak   	
   	li $s2, 0		# zeruje $s2, bo petle zaczynam od warunku
   					
     dekoduje:
    lb $s1, ($t8)
   	lb $s2, ($t7)
   	beq $s2, '.', znaleziony
   	addu $t7, $t7, 1
   	addu $t8, $t8, 1
   	bne $s1, $s2, rozne 
      b dekoduje
   
   rozne: 	
   	addu $t6, $t6, 1
   	
   	# przesuwam na kolejna konfuguracje w tab_kresek
      tab_kresek:
   	lb $s2, ($t7)
   	addu $t7, $t7, 1
   	beq $s2, '\n', koniec_wczytywania
   	bne $s2, '.', tab_kresek   	
   	j wczytany 	
   	
   znaleziony:
   	lb $s3, ($t6)		# sprawdzam jaki to znak
   	beq $s3, '*', koniec_wczytywania
   	addu $a1, $a1, 1	# licznik znakow w kodzie
   	sb $s3, ($t9)		# zapisuje znak w tablicy kodu
   	addu $t9, $t9, 1	# przesuwam wskaznik w tablicy kodu
   	
   	j  zaczynam_zczytywac_znak		# znowu to samo
 ###################################  	
   	
   koniec_wczytywania:		# $t9 na znaku kontrolnym
   	subu $t9, $t9,1
   	lb $s5, ($t9)		# s5 zawiera znak kontrolny, ktory sprawdze   	   	
   	la $s4, Code		# ustawiam $s4 na poczatek tablicy zdekodowanych symboli, aby obliczyc znak kontrolny
   	li $t4, 0		# licznik znaku kontrolnego
   	li $s7, 0
   	li $t7, 0		# wskaznik na tablice kresek juz niepotrzebny
   	#li $t1, 0		#szerokosci paskow nie sa mi juz potrzebne- przechowuje wartosc dla znaku
   	li $t2, 0
   	
      znak_kontrolny:
      	addu $s7, $s7, 1
      	beq $s7, $a1, obliczony	# koniec jesli liczba zsumowanych rowna liczbie znakow w kodzie
      	lb $s6, ($s4)		# wczytuje bajt      	
      	addu $s4, $s4, 1
      	la $t6, Tablica_znakow
      	addu $t6, $t6, 1	# ustawiam na pierwszy znak
      	li $t1, 0
      	
      znajdz_numer_znaku:
      	lb $t2, ($t6)
      	addu $t6, $t6, 1
      	beq $t2, $s6, znaleziony_numer
      	addu $t1, $t1, 1
      b znajdz_numer_znaku
      	znaleziony_numer:
      		
      	beq $s6, '\0', error3   
      	znak_kontrolny2:	
      	addu $t4, $t4, $t1   	
      	ble $t4, 42, znak_kontrolny
      	subu $t4, $t4, 43
     b znak_kontrolny
      	
        obliczony:	
      	la $t6, Tablica_znakow
      	addu $t6, $t6, 1	# ustawiam na pierwszy znak
      	li $t1, 0
      	dekoduje_znak_kontrolny:
      	lb $t2, ($t6)		# $t2 bedzie zawieral znak kontrolny
      	addu $t6, $t6, 1
      	beq $t1, $t4, kontrola
      	addu $t1, $t1, 1
      	b dekoduje_znak_kontrolny
      	
      	kontrola:      	 
      	bne $s5, $t2, error3
      	
      	li $s6, '\n'	# zastepuje znak kontrolny znakiem nowej linii
      	sb $s6, ($s4)
      	
   wyswietlam_kod:
   	li $v0, 4
	la $a0, Code
	syscall	

# zamknij plik:
  li   $v0, 16       # system call for close file
 	move $a0, $t0      # file descriptor to close
	syscall            # close file

exit:
	li $v0, 10
	syscall

#Nie powiodlo sie otwarcie pliku
error:
# wystapil blad przy odczycie pliku - wyswietlamy komunikat
	li $v0, 4
	la $a0, err	
	syscall

# exit:
	li $v0, 10
	syscall

error2:
        # zly rozmiar obrazka - wyswietlamy komunikat
	li $v0, 4
	la $a0, err2	
	syscall
# zamknij plik:
  li   $v0, 16       # system call for close file
 	move $a0, $t0      # file descriptor to close
	syscall            # close file

# exit:
	li $v0, 10
	syscall

error3: #zly znak kontrolny
	li $v0, 4
	la $a0, err3	
	syscall
# zamknij plik:
        li   $v0, 16       # system call for close file
 	move $a0, $t0      # file descriptor to close
	syscall            # close file

# exit:
	li $v0, 10
	syscall

