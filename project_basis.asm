.data
victory: .asciiz "victory"		#Victory text
naam: .asciiz "input.txt"		#Input file
buffer: .space 2048 			#Plaats om inhoud van file te plaatsen
.text

#Main functie die het doolhof invoert en naar gameloop srpingt
main:
	jal openMaze			#Springt naar openMaze
	jal game			#Springt naar GameLoop
	j endGame
	
#Opent een file en voegt het in de display
openMaze:
	#StackFrame
	sw	$fp, 0($sp)	# push old frame pointer (dynamic link)
	move	$fp, $sp	# frame	pointer now points to the top of the stack
	subu	$sp, $sp, 16	# allocate 16 bytes on the stack
	sw	$ra, -4($fp)	# store the value of the return address
	sw	$s6, -8($fp)	# save locally used registers

	#Laadt kleuren in
	li $t1, 0x00000000    		#De kleur zwart opslaan in $t1
	li $t2, 0x00ffff00     		#De kleur geel opslaan in $t2
	li $t3, 0x000ff000     		#De kleur Groen opslaan in $t1
	li $t4, 0x000000ff     		#De kleur Blauw opslaan in $t2

	#Opent een file
	li $v0, 13 			#Load code voor het opnenen van een file
	la $a0, naam			#Naam van de file wordt opgeslagen in $a0
	li $a1, 0 			#Open voor schijven (flags are 0: read, 1: write)
	li $a2, 0 			#Mode is ignored
	syscall 			#Opent de file
	move $s6, $v0 			#verplaatst de file naar $s6

	#Leest een file
	li $v0, 14 			#Load code voor het lezen van een file
	move $a0, $s6 			#Zet file in $a0
	la $a1, buffer 			#Buffer wordt opgeslagen in $t0
	li $a2, 2048 			# hardcoded max number of characters (equal to size of buffer)
	syscall 			#Leest de file
	
	#Elk karakter afgaan
	la $s2, buffer			#Slaat buffer op in s2
	move $s3, $s2			#addres van buffer wordt opgeslagen in $s3
	add $s3, $s3, $v0		#$s3 staat voor het limiet van de buffer dus moet worden opgeteld met aantal bytes die zijn ingelezen
	move $a3, $gp            	#Beginpositie van pixels ($gp)
	
	loop1:
		bge $s2,$s3, exit	#Als alle karakters van de text file overlopen zijn, spring dan naar exit	
		lb $t0, 0($s2)		#Slaat het karakter op in $t3
		
		beq $t0, '\n', enter1	#Als het karakter gelijk is aan enter, Spring dan naar enter
		beq $t0, 'w', maakBlauw	#Als het karakter gelijk is aan w, Spring dan naar maakBlauw
		beq $t0, 'p', maakRood	#Als het karakter gelijk is aan p, Spring dan naar maakRood
		beq $t0, 's', maakGeel	#Als het karakter gelijk is aan s, Spring dan naar maakGeel
		beq $t0, 'u', maakGroen	#Als het karakter gelijk is aan u, Spring dan naar MaakGroen
	
		addi $s2, $s2, 1	#Als het geen van bovenstaande is, ga dan naar het volgende karakter
		j loop1			#Spring terug naar loop1

#Sluit de file en reset alle onnodige registers ($t1 en $t2 blijven staan voor later het bewegen van de speler)
exit:
	#Zet alle registers die niet meer gebruikt moeten worden naar 0
	add $t0, $zero, $zero
	add $t3, $zero, $zero
	add $t4, $zero, $zero
	add $t5, $zero, $zero
	add $t6, $zero, $zero
	add $t7, $zero, $zero

	add $a0, $zero, $zero
	add $a1, $zero, $zero
	add $a2, $zero, $zero
	add $a3, $zero, $zero
	
	add $s2, $zero, $zero
	add $s3, $zero, $zero
	add $s6, $zero, $zero
	

	#Sluit de file
	li $v0, 16 			#Load code voor eindigen van files
	move $a0, $s6 			#file dat is opgeslagen in $s16 moet worden gesloten
	syscall 			#Sluit de file
	
	#StackFrame
	lw	$s6, -8($fp)	# reset saved register $s6
	lw	$ra, -4($fp)    # get return address from frame
	move	$sp, $fp        # get old frame pointer from current fra
	lw	$fp, ($sp)	# restore old frame pointer
	jr	$ra

#Maakt een pixel rood
maakRood:
	sw $t1, ($a3)      		#Maak de pixel rood
	j next				#Spring naar next

#Maakt een pixel geel
maakGeel:
	sw $t2, ($a3)      		#Maak de pixel geel
	addi $t8, $t6, 1		#Sla de kolom positie op
	add $t9, $t7, $zero		#Sla de rij positie op
	j next				#Spring naar next
	
#Maakt een pixel groen
maakGroen:
	sw $t3, ($a3)      		#Maak de pixel groen
	j next				#Spring naar next
    
#Maakt een pixel blauw
maakBlauw:
	sw $t4, ($a3)      		#Maak de pixel blauw
	j next				#Spring naar next

#Gaat naar het volgend karakter en pixel
next:
	addi $a3, $a3, 4     		#Naar volgende pixel gaan (register optellen met 1 word)
	addi $s2, $s2, 1		#Naar volgend karakter gaan
	addi $t6, $t6, 1		
	j loop1				#Spring naar loop1

#Springt naar de volgende rij
enter1:
	subi $t5, $a3, 0x10008000	#Trekt beginpositie af van current positie
	ble $t5, 0x80, continue		#Als $t5 kleiner is dan 128 gaat het verder
	modulo:				#Modulo berekenen
		subi $t5, $t5, 0x80	#Trekt 128 af van $t5
		ble $t5, 0x80, continue	#Gaat verder als $t5 kleiner is dan 128
		j modulo		#Srpingt terug naar de modulo
	continue: 
		addi $t6, $zero, 0x80	#Zet 128 in $t6
		sub $t5, $t6, $t5	#Trekt de positie af van 128 en slaat het op in $t5

		add $a3, $a3, $t5    	#Naar volgende rij gaan (register optellen met n aantal woorden)
		addi $s2, $s2, 1	#Volgende karakter in buffer
		addi $t7, $t7, 1	#Volgende rij
		addi $t6, $zero, -1	#Kolom is terug 0
		j loop1			#Springt naar loop1

#Loop die bljift herhalen en wacht op input tot het einde bereikt wordt
game:
   
   #StackFrame
   sw	$fp, 0($sp)	# push old frame pointer (dynamic link)
   move	$fp, $sp	# frame	pointer now points to the top of the stack
   subu	$sp, $sp, 4	# allocate 16 bytes on the stack
   sw	$ra, -4($fp)	# store the value of the return address
   sw	$s0, -8($fp)	# save locally used registers


   subi $sp, $sp, 4			#Gaat naar volgende positie in stack
   sw $ra, ($sp)			#Slaat $ra op
   loop2:
	jal sleep			#springt naar sleep
	lui $a3, 0xffff			#Load upper immediate van het eerste word in $a3
	addi $a0, $v0,0			#$a0 = $v0
	loop3:				#loop
		lw $t4, 0($a3)		#value wordt opgeslagen in $t1
		andi $t4, $t4, 0x1	#And immediate van $t1 -> alle nullen vooraan weglaten zodat we een single value krijgen
		beqz $t4, loop3		#Als er geen karakter is ingegeven moet het terug naar loop springen 
	lw $v0, 4($a3)			#ingegeven karakter (als ascii value) wordt opgeslagen in $v0

					#Check if equal to z,s,q,d,x
	beq $v0, 'z', goUp		#		.
	beq $v0, 's', goDown		#		.
	beq $v0, 'q', goLeft		#		.
	beq $v0, 'd', goRight		#		.
	beq $v0, 'x', end		#		.
	j loop2				#Keert terug naar de loop
	
#Eindigt de game loop en keert terug naar de main functie
end:
	lw $ra, ($sp)			#Zet $ra juist
	addi $sp, $sp, 4		#Gaat terug naar vorige positie in stack
	
	#StackFrame
	lw	$s0, -8($fp)	# reset saved register $s0
	lw	$ra, -4($fp)    # get return address from frame
	move	$sp, $fp        # get old frame pointer from current fra
	lw	$fp, ($sp)	# restore old frame pointer
	jr	$ra

#Wacht enkele miniseconden vooraleer er een nieuwe input kan worden doorgegeven
sleep:
	
	#StackFrame
	sw	$fp, 0($sp)	# push old frame pointer (dynamic link)
	move	$fp, $sp	# frame	pointer now points to the top of the stack
	subu	$sp, $sp, 16	# allocate 16 bytes on the stack
	sw	$ra, -4($fp)	# store the value of the return address
	sw	$s0, -8($fp)	# save locally used registers

	li $v0, 32			#Code voor het programma te laten wachten
	li $a0, 60			#Laadt 2000 in in $a0 (2000 miliseconden)
	syscall				#Voert het uit
	
	#StackFrame
	lw	$s0, -8($fp)	# reset saved register $s0
	lw	$ra, -4($fp)    # get return address from frame
	move	$sp, $fp        # get old frame pointer from current fra
	lw	$fp, ($sp)	# restore old frame pointer
	jr	$ra

#Nieuwe positie wordt aangemaakt
goUp:
	addi $a1, $t8, 0		#Nieuwe kolompositie
	addi $a2, $t9, -1		#Nieuwe rijpositie
	j updatePos			#Jump naar updatePos
	
#Nieuwe positie wordt aangemaakt
goDown:
	addi $a1, $t8, 0		#Nieuwe kolompositie
	addi $a2, $t9, 1		#Nieuwe rijpositie
	j updatePos			#Jump naar updatePos
	
#Nieuwe positie wordt aangemaakt
goLeft:
	addi $a1, $t8, -1		#Nieuwe kolompositie
	addi $a2, $t9, 0		#Nieuwe rijpositie
	j updatePos			#Jump naar updatePos
	
#Nieuwe positie wordt aangemaakt
goRight:
	addi $a1, $t8, 1		#Nieuwe kolompositie
	addi $a2, $t9, 0		#Nieuwe rijpositie
	j updatePos			#Jump naar updatePos


#Kijkt na of de gegeven positie geldig is
updatePos:
	mul $t3, $a1, 0x4 		#Vermenigvuldig de kolom met 4
	mul $t4, $a2, 0x80		#Vermenigvuldig de rij met 128
	add $t5, $t3, $t4		#Tel ze bij elkaar op
	addi $gp, $t5, 0x10008000	#pas $gp aan naar juiste addres
	
	lw $t3, ($gp)			#Zet de positie van $gp in $t3
	beq $t3, 0x00000000, canMove	#Als de pixel wart is, jump naar canMove
	beq $t3, 0x000000ff, loop2	#Als de pixel blauw is, jump terug naar gameLoop
	beq $t3, 0x000ff000, finish	#Als de pixel groen is, jump naar finish
	
#functie die wordt aangeroepen om de speler te verplaatsen
canMove:
	sw $t2, ($gp)      		#Maak de pixel geel
	mul $t3, $t8, 0x4 		#Vermenigvuldig de kolom met 4
	mul $t4, $t9, 0x80		#Vermenigvuldig de rij met 128
	add $t5, $t3, $t4		#Tel ze bij elkaar op
	addi $gp, $t5, 0x10008000	#pas $gp aan naar juiste addres
	sw $t1, ($gp)      		#Maak de pixel rood
	move $t8, $a1			#Zet de rij positie op de nieuwe positie
	move $t9, $a2			#Zet de kolom positie op de nieuwe positie
	j loop2				#Springt naar endGame

#Geeft aan dat de finish bereikt is	
finish:
	sw $t2, ($gp)      		#Maak de pixel geel
	mul $t3, $t8, 0x4 		#Vermenigvuldig de kolom met 4
	mul $t4, $t9, 0x80		#Vermenigvuldig de rij met 128
	add $t5, $t3, $t4		#Tel ze bij elkaar op
	addi $gp, $t5, 0x10008000	#pas $gp aan naar juiste addres
	sw $t1, ($gp)      		#Maak de pixel rood
	move $t8, $a1			#Zet de rij positie op de nieuwe positie
	move $t9, $a2			#Zet de kolom positie op de nieuwe positie
	li $v0, 4			#Load code voor victory
	la $a0, victory			#Laadt victory in in $a0
	syscall				#Print het uit
	j end				#Springt naar end

#Beeindigt het spel
endGame:				
	li $v0, 10			#Load code voor exit
	syscall				#Eidigt het programma
	
