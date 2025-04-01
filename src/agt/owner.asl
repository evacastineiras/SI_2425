/* Initial Beliefs */
connect(kitchen, hall, doorKit1).
connect(kitchen, hallway, doorKit2).
connect(hall, kitchen, doorKit1).
connect(hallway, kitchen, doorKit2).
connect(bath1, hallway, doorBath1).
connect(bath2, bedroom1, doorBath2).
connect(hallway, bath1, doorBath1).
connect(bedroom1, bath2, doorBath2).
connect(bedroom1, hallway, doorBed1).
connect(hallway, bedroom1, doorBed1).
connect(bedroom2, hallway, doorBed2).
connect(hallway, bedroom2, doorBed2).
connect(bedroom3, hallway, doorBed3).
connect(hallway, bedroom3, doorBed3).
connect(hall,livingroom, doorSal1).                       
connect(livingroom, hall, doorSal1).
connect(hallway,livingroom, doorSal2).
connect(livingroom, hallway, doorSal2).

/*Initial prescription beliefs*/
pauta(paracetamol, 25). //paracetamol
pauta(ibuprofeno, 30). //ibuprofeno
pauta(dalsi, 25). // dalsy
pauta(frenadol, 40). //frenadol
pauta(aspirina, 50).

medicPend([]). // Donde vamos a manejar los medicamentos que tiene que tomar owner
/* Initial goals */

//Owner will send his prescription to the robot
// Owner will simulate the behaviour of a person 
// We need to characterize their digital twin (DT)
// Owner must record the DT data periodically 
// Owner must access the historic data of such person
// Owner will act randomly according to some problems
// Owner will usually act with a behaviour normal
// Owner problems will be activated by some external actions
// Owner problems will randomly be activated on time
// Owner will dialog with the nurse robot 
// Owner will move randomly in the house by selecting places



!sit.

!send_pauta.


!open.

!walk.

!wakeup.

!check_bored.

// Initially Owner could be: sit, opening the door, waking up, walking, ...
//!sit.   			
//!check_bored. 

//+!init <- !sit ||| !open ||| !walk ||| !wakeup ||| !check_bored.

+!send_pauta : true  <-
	.findall(pauta(X,Y), pauta(X,Y), L);
	.print("Mi pauta: ", L);
	.send(enfermera, tell, L);
	.send(enfermera,achieve,inicia);
	!inicia.


+!inicia : true <- 
    .print("Iniciando recordatorios de medicamentos...");
    .time(H, M, S);
    .findall(consumo(X,T,H,M,S), pauta(X,T), L);
    !iniciarContadores(L);
    !tomarMedicina.
+!iniciarContadores([consumo(Medicina,T,H,M,S)|Cdr]) <-
    if(S+T>=60){ //  Si la siguiente pauta me va a hacer cambiar de minuto, le resto 60. Ej. Me lo voy tomar a 50, si siguiente pauta es 15== 65.
		+consumo(Medicina,T,H,M+1,S+T-60);
		.print(consumo(Medicina,T,H,M+1,S+T-60));	
	}else{
		+consumo(Medicina,T,H,M,S+T);
		.print(consumo(Medicina,T,H,M,S+T));
	}
	
    !iniciarContadores(Cdr).
+!iniciarContadores([]) <- .print("Inicialización completada").

/* MISMA HORA Y MINUTO 19 39 29     38   8<=2-29*/						  // ahora son 58 y 50 es la ultima vez que tomaste 58-50==8==pauta--> 15-10 <= 56-50 --> entra
+!tomarMedicina: pauta(Medicina,T) & consumo(Medicina,T,H,M,S) & .time(H,M,SS) & 15 >= S-SS  & medicPend(Med) <- // Funciona por que S siempre es anterior
	.println("MISMO MINUTO");
	.println("Me tengo que tomar ",Medicina, " a las: ",H,":",M,":",S);
	.println("Voy a ir llendo a por ", Medicina, " a las: ",H,":",M,":",SS);
	if(S+T>=60){ //  Si la siguiente pauta me va a hacer cambiar de minuto, le resto 60. Ej. Me lo voy tomar a 50, si siguiente pauta es 15== 65.
		+consumo(Medicina,T,H,M+1,S+T-60);	
	}else{
		+consumo(Medicina,T,H,M,S+T);
	}.

+!tomarMedicina: pauta(Medicina,T) & consumo(Medicina,T,H,M,S) & .time(H,MM,SS) & M == MM+1 & S<15 & 15 >= (60-SS)+(S) & medicPend(Med) <-
    .println("DISTINTO MINUTO");
    //  Si la siguiente pauta me va a hacer cambiar de minuto, le resto 60. Ej. Me lo voy tomar a 50, si siguiente pauta es 15== 65.
	.println("Me tengo que tomar ",Medicina, " a las: ",H,":",M,":",S);	
	.println("Voy a ir llendo a por ", Medicina, " a las: ",H,":",MM,":",SS);
	if(S+T>=60){ //  Si la siguiente pauta me va a hacer cambiar de minuto, le resto 60. Ej. Me lo voy tomar a 50, si siguiente pauta es 15== 65.
		+consumo(Medicina,T,H,M+1,S+T-60);	
	}else{
		+consumo(Medicina,T,H,M,S+T);
	}.

/* NADA QUE TOMAR */
+!tomarMedicina <- 
    .wait(10);
    !tomarMedicina.


+!wakeup : .my_name(Ag) & not busy <-
	+busy;
	!check_bored;
	.println("Owner just woke up and needs to go to the fridge"); 
	.wait(3000);
	-busy;
	!sit.
+!wakeup : .my_name(Ag) & busy <-
	.println("Owner is doing something now, is not asleep");
	.wait(10000);
	!wakeup.
	
+!walk : .my_name(Ag) & not busy <- 
	+busy;  
	.println("Owner is not busy, is sit down on the sofa");
	.wait(500);
	!at(Ag,sofa);
	.wait(2000);
	//.println("Owner is walking at home"); 
	-busy;
	!open.
+!walk : .my_name(Ag) & busy <-
	.println("Owner is doing something now and could not walk");
	.wait(6000);
	!walk.

+!open : .my_name(Ag) & not busy <-
	+busy;   
	.println("Owner goes to the home door");
	.wait(200);
	!at(Ag, delivery);
	.println("Owner is opening the door"); 
	.random(X); .wait(X*7351+2000); // Owner takes a random amount of time to open the door 
	!at(Ag, sofa);
	sit(sofa);
	.wait(5000);
	!at(Ag, fridge);
	.wait(10000);
	!at(Ag, chair3);
	sit(chair3);
	-busy.
+!open : .my_name(Ag) & busy <-
	.println("Owner is doing something now and could not open the door");
	.wait(8000);
	!open.
 
+!sit : .my_name(Ag) & not busy <- 
	+busy; 
	.println("Owner goes to the fridge to get a beer.");
	.wait(1000);
	!at(Ag, fridge);
	.println("Owner is hungry and is at the fridge getting something"); 
	//.println("He llegado al frigorifico");
	.wait(20);
	!at(Ag, chair3);
	sit(chair3);
	.wait(40);
	!at(Ag, chair4);
	sit(chair4);
	.wait(40);
	!at(Ag, chair2);
	sit(chair2);
	.wait(40);
	!at(Ag, chair1);
	sit(chair1);
	.wait(40);
	!at(Ag, sofa);
	sit(sofa);
	.wait(100);
	-busy.
+!sit : .my_name(Ag) & busy <-
	.println("Owner is doing something now and could not go to fridge");
	.wait(300);
	!sit.

+!at(Ag, P) : at(Ag, P) <- 
	.println("Owner is at ",P);
	.wait(500).
+!at(Ag, P) : not at(Ag, P) <- 
	.println("Going to ", P);
	!go(P);                                        
	.println("Checking if is at ", P);
	!at(Ag, P).            
	                                                   
+!go(P) : atRoom(RoomAg) & atRoom(P, RoomAg) <-                             
	//.println("Al estar en la misma habitación se debe mover directamente a: ", P);
	move_towards(P).  
+!go(P) : atRoom(RoomAg) & atRoom(P, RoomP) & not RoomAg == RoomP &
		  connect(RoomAg, RoomP, Door) & atDoor(Door) <-
	//.println("Al estar en la puerta ", Door, " se dirige a ", P);                        
	move_towards(P); 
	!go(P).       
+!go(P) : atRoom(RoomAg) & atRoom(P, RoomP) & not RoomAg == RoomP &
		  connect(RoomAg, RoomP, Door) & not atDoor(Door) <-
	//.println("Al estar en una habitación contigua se mueve hacia la puerta: ", Door);
	move_towards(Door); 
	!go(P).  
+!go(P) : atRoom(RoomAg) & atRoom(P, RoomP) & not RoomAg == RoomP &
		  not connect(RoomAg, RoomP, _) & connect(RoomAg, Room, DoorR) &
		  connect(Room, RoomP, DoorP) & atDoor(DoorR) <-
	//.println("Se mueve a: ", DoorP, " para ir a la habitación ", RoomP);
	move_towards(DoorP); 
	!go(P).      
+!go(P) : atRoom(RoomAg) & atRoom(P, RoomP) & not RoomAg == RoomP &
		  not connect(RoomAg, RoomP, _) & connect(RoomAg, Room, DoorR) &
		  connect(Room, RoomP, DoorP) & not atDoor(DoorR) <-
	//.println("Se mueve a: ", DoorR, " para ir a la habitación contigua, ", Room);
	move_towards(DoorR); 
	!go(P). 

+!go(P) : atRoom(RoomAg) & atRoom(P, RoomP) & not RoomAg == RoomP <-
	//.println("Owner is at ", RoomAg,", that is not a contiguous room to ", RoomP);
	move_towards(P).                                                          
-!go(P) <- .println("Something goes wrong......").
	                                                                        
	
+!get(drug) : .my_name(Name) <- 
   Time = math.ceil(math.random(4000));
   .println("I am waiting ", Time, " ms. before asking the nurse robot for my medicine.");
   .wait(Time);
   .send(enfermera, achieve, has(Name, drug)).

+has(owner,drug) : true <-
   .println("Owner take the drug.");
   !take(drug).
-has(owner,drug) : true <-
   .println("Owner ask for drug. It is time to take it.");
   !get(drug).
                                       
// while I have drug, sip
+!take(drug) : has(owner, drug) <-
   sip(drug);
   .println("Owner is siping the drug.");
   !take(drug).
+!take(drug) : not has(owner, drug) <-
   .println("Owner has finished to take the drug.").//;
   //-asked(drug).

+!check_bored : true
   <- .random(X); .wait(X*5000+2000);  // Owner get bored randomly
      .send(enfermera, askOne, time(_), R); // when bored, owner ask the robot about the time
      .print(R);
	  .send(enfermera, tell, chat("What's the weather in Ourense?"));
      !check_bored.

+msg(M)[source(Ag)] : .my_name(Name)
   <- .print(Ag, " send ", Name, " the message: ", M);
      -msg(M).


