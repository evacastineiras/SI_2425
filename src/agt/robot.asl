/* Initial beliefs and rules */

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
connect(hall, livingroom, doorSal1).        
connect(livingroom, hall, doorSal1).
connect(hallway, livingroom, doorSal2).       
connect(livingroom, hallway, doorSal2).     

// initially, robot is free
free.

// initially, I believe that there is some drug in the fridge
available(drug, fridge).

// my owner should not consume more than 10 drugs a day :-)
limit(drug,10).  
                 
too_much(B, Ag) :-
   .date(YY, MM, DD) &
   .count(consumed(YY, MM, DD, _, _, _, B, Ag), QtdB) &   
   limit(B, Limit) &    
   .println(Ag," has consumed ", QtdB, " ", B, " their limit is: ", Limit) &
   QtdB > Limit-1. 
   
answer(Request, "It will be nice to check the weather forecast, don't?.") :-
	.substring("tiempo", Request).  
	
answer(Request, "I don't understand what are you talking about.").

bringDrug(Ag) :- available(drug, fridge) & not too_much(drug, Ag).

orderDrug(Ag) :- not available(drug, fridge) & not too_much(drug, Ag).  

/* Plans */


+!inicia : true <- 
    .print("Iniciando recordatorios de medicamentos...");
    .time(H, M, S);
    .findall(consumo(X,T,H,M,S), pauta(X,T), L);
    !iniciarContadores(L);
    !tomarMedicina.
+!iniciarContadores([Car|Cdr]) <-
    +Car;
    !iniciarContadores(Cdr).
+!iniciarContadores([]) <- .print("Inicialización completada").

/* MISMA HORA Y MINUTO */
+!tomarMedicina: pauta(X,T) & consumo(X,T,H,M,S) & .time(H,M,SS) & T <= SS-S <-
    .println("Hora de tomar ",X, " son las: ",H,":",M,":",SS);
	!has(owner,X);
    .abolish(consumo(X,T,H,M,S));
    +consumo(X,T,H,M,SS);
    !tomarMedicina.

/* MISMA HORA DISTINTO MINUTO */
+!tomarMedicina: pauta(X,T) & consumo(X,T,H,M,S) & .time(H,MM,SS) & M \== MM & D = 60-S & T <= SS+D <-
    .println("Hora de tomar ",X, " son las: ",H,":",MM,":",SS);
	!has(owner,X);
    .abolish(consumo(X,T,H,M,S));
    +consumo(X,T,H,MM,SS);
    !tomarMedicina.

/* DISTINA HORA DISTINTO MINUTO */
+!tomarMedicina: pauta(X,T) & consumo(X,T,H,M,S) & .time(HH,MM,SS) & H \== HH & D = 60-S & T <= SS+D <-
    .println("Hora de tomar ",X, " son las: ",HH,":",MM,":",SS);
	!has(owner,X);
    .abolish(consumo(X,T,H,M,S));
    +consumo(X,T,HH,MM,SS);
    !tomarMedicina.

/* NADA QUE TOMAR */
+!tomarMedicina <- 
    .println("Nada que tomar");
    .wait(1000);
    !tomarMedicina.

+!has(Ag, Medicina): free[source(self)] <- 
		.println("FIRST RULE ====================================");
		.wait(1000);
		//!at(enfermera, owner); 
    	-free[source(self)];      
		!at(enfermera, fridge);
		
		open(fridge); // Change it by an internal operation similar to fridge.open
		getMedicina(Medicina);
		close(fridge);// Change it by an internal operation similar to fridge.close
		!at(enfermera, Ag);
		mano_en(Medicina);	// In this case this operation could be external or internal their intention
		              		// is to inform that the owner has the drug in his hand and could begin to drink
							// remember that another drug has been consumed
		.date(YY, MM, DD); .time(HH, NN, SS);
		+consumed(YY, MM, DD, HH, NN, SS, drug, Ag);
		+free[source(self)]. 

/*
+!has(Ag, Medicina)[source(Ag)] : 
	bringDrug(Medicina) & free[source(self)] <- 
		.println("FIRST RULE ====================================");
		.wait(1000);
		//!at(enfermera, owner); 
    	-free[source(self)];      
		!at(enfermera, fridge);
		
		open(fridge); // Change it by an internal operation similar to fridge.open
		getMedicina(Medicina);
		close(fridge);// Change it by an internal operation similar to fridge.close
		!at(enfermera, Ag);
		hand_in(Medicina);// In this case this operation could be external or internal their intention
		              // is to inform that the owner has the drug in his hand and could begin to drink
		?has(Ag, Medicina);  // If the previous action is completed then a perception from environment must update
		                 // the beliefs of the robot
						 
		// remember that another drug has been consumed
		.date(YY, MM, DD); .time(HH, NN, SS);
		+consumed(YY, MM, DD, HH, NN, SS, drug, Ag);
		+free[source(self)].  

// This rule was changed in order to find the deliver in a different location 
// The door could be a good place to get the order and then go to the fridge
// and when the drug is there update the beliefs
*/
+!has(Ag, drug)[source(Ag)] :
   	orderDrug(Ag) & free[source(self)] <- 
		.println("SECOND RULE ====================================");
		.wait(1000);
   		-free[source(self)]; 
		!at(enfermera, fridge);
		.send(repartidor, achieve, order(drug, 5)); 
		!at(enfermera, delivery);     // go to deliver area and wait there.
		.wait(delivered);
		!at(enfermera, fridge);       // go to fridge 
		deliver(Product,5);
		+available(drug, fridge); 
		+free[source(self)];
		.println("Trying to bring drug after order it");
		!has(Ag, drug)[source(Ag)].               

// A different rule provided to not block the agent with contradictory petitions

+!has(Ag, drug)[source(Ag)] :
   	not free[source(self)] <- 
		.println("THIRD RULE ====================================");
		.println("The robot is busy and cann't attend the order now."); 
		.wait(4000);
		!has(Ag, drug).   
		
+!has(Ag, drug)[source(Ag)] 
   :  too_much(drug, Ag) & limit(drug, L) <-
      	.println("FOURTH RULE ====================================");
		.wait(1000);
		.concat("The Department of Health does not allow me to give you more than ", L,
                " drugs a day! I am very sorry about that!", M);
		.send(Ag, tell, msg(M)).

// If some problem appears, we manage it by informing the intention that fails 
// and the goal is trying to satisfy. Of course we can provide or manage the fail
// better by using error annotations. Remember examples on slides when introducing
// intentions as a kind of exception      

-!has(Name, P) <-
//   :  true
// No condition is the same that a constant true condition
	.println("FIFTH RULE ====================================");
	.wait(1000);
	.current_intention(I);
    .println("Failed to achieve goal: !has(", Name, " , ", P, ").");
	.println("Current intention is: ", I).

+!at(Ag, P) : at(Ag, P) <- 
	.println(Ag, " is at ",P);
	.wait(500).
+!at(Ag, P) : not at(Ag, P) <- 
	.println("Going to ", P, " <=======================");  
	.wait(200);
	!go(P);                                        
	.println("Checking if is at ", P, " ============>");
	!at(Ag, P).            
	                                                   
+!go(P) : atRoom(RoomAg) & atRoom(P, RoomAg) <- 
	.println("<================== 1 =====================>");
	.println("Al estar en la misma habitación se debe mover directamente a: ", P);
	move_towards(P).  
+!go(P) : atRoom(RoomAg) & atRoom(P, RoomP) & not RoomAg == RoomP &
		  connect(RoomAg, RoomP, Door) & not atDoor(Door) <-
	.println("<================== 3 =====================>");
	.println("Al estar en una habitación contigua se mueve hacia la puerta: ", Door);
	move_towards(Door); 
	!go(P).                     
+!go(P) : atRoom(RoomAg) & atRoom(P, RoomP) & not RoomAg == RoomP &
		  connect(RoomAg, RoomP, Door) & not atDoor(Door) <- 
	.println("<================== 3 =====================>");
	.println("Al estar en la puerta de la habitación contigua se mueve hacia ", P);
	move_towards(P); 
	!go(P).       
+!go(P) : atRoom(RoomAg) & atRoom(P, RoomP) & not RoomAg == RoomP &
		  not connect(RoomAg, RoomP, _) & connect(RoomAg, Room, DoorR) &
		  connect(Room, RoomP, DoorP) & atDoor(DoorR) <-
	.println("<================== 4 BIS =====================>");
	.println("Se mueve a: ", DoorP, " para acceder a la habitación ", RoomP);
	move_towards(DoorP); 
	!go(P). 
+!go(P) : atRoom(RoomAg) & atRoom(P, RoomP) & not RoomAg == RoomP &
		  not connect(RoomAg, RoomP, _) & connect(RoomAg, Room, DoorR) &
		  connect(Room, RoomP, DoorP) & not atDoor(DoorR) <-
	.println("<================== 4 =====================>");
	.println("Se mueve a: ", DoorR, " para ir a la habitación contigua, ", Room);
	move_towards(DoorR); 
	!go(P). 
+!go(P) : atRoom(RoomAg) & atRoom(P, RoomP) & not RoomAg == RoomP <- //& not atDoor <-
	.println("Owner is at ", RoomAg,", that is not a contiguous room to ", RoomP);
	.println("<================== 5 =====================>");
	move_towards(P).                                                          
-!go(P) <- 
	.println("¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿ WHAT A FUCK !!!!!!!!!!!!!!!!!!!!");
	.println("..........SOMETHING GOES WRONG......").                                        
	                                                                        
// when the supermarket makes a delivery, try the 'has' goal again
+delivered(drug, _Qtd, _OrderId)[source(repartidor)]
  :  true
  <- +delivered;
	 .wait(2000). 
	 
	 // Code changed from original example 
	 // +available(drug, fridge);
     // !has(owner, drug).

// When the fridge is opened, the drug stock is perceived
// and thus the available belief is updated
+stock(drug, 0)
   :  available(drug, fridge)
   <- -available(drug, fridge). 
   
+stock(drug, N)
   :  N > 0 & not available(drug, fridge)
   <- +available(drug, fridge).     
   
+chat(Msg)[source(Ag)] : answer(Msg, Answ) <-  
	.println("El agente ", Ag, " me ha chateado: ", Msg);
	.send(Ag, tell, msg(Answ)). 
                                     
+?time(T) : true
  <-  time.check(T).



