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
                 

 

medicPend([]). // Donde vamos a manejar los medicamentos que tiene que tomar owner

/* Plans */


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
	.println("Owner debe tomar ",Medicina, " a las: ",H,":",M,":",S);
	.println("Voy a ir llendo a por ", Medicina, " a las: ",H,":",M,":",SS);	
	//!has(owner,X);
	!addMedicina(Medicina);
	!!aPorMedicina(Medicina,H,M,S);
    .abolish(consumo(Medicina,T,H,M,S));
	if(S+T>=60){ //  Si la siguiente pauta me va a hacer cambiar de minuto, le resto 60. Ej. Me lo voy tomar a 50, si siguiente pauta es 15== 65.
		+consumo(Medicina,T,H,M+1,S+T-60);	
	}else{
		+consumo(Medicina,T,H,M,S+T);
	}
	.belief(consumo(Medicina,_,_,MMM,SSS));
	.println("Actualizado consumo a min: ",MMM," seg: ",SSS);
    !tomarMedicina.

+!tomarMedicina: pauta(Medicina,T) & consumo(Medicina,T,H,M,S) & .time(H,MM,SS) & M == MM+1 & S<15 & 15 >= (60-SS)+(S) & medicPend(Med) <-
    .println("DISTINTO MINUTO");
    //  Si la siguiente pauta me va a hacer cambiar de minuto, le resto 60. Ej. Me lo voy tomar a 50, si siguiente pauta es 15== 65.
	.println("Owner debe tomar ",Medicina, " a las: ",H,":",M,":",S);	
	
	.println("Voy a ir llendo a por ", Medicina, " a las: ",H,":",MM,":",SS);
    !addMedicina(Medicina);
    !!aPorMedicina(Medicina,H,M,S);
    .abolish(consumo(Medicina,T,H,M,S));
    if(S+T>=60){ //  Si la siguiente pauta me va a hacer cambiar de minuto, le resto 60. Ej. Me lo voy tomar a 50, si siguiente pauta es 15== 65.
		+consumo(Medicina,T,H,M+1,S+T-60);	
	}else{
		+consumo(Medicina,T,H,M,S+T);
	}
	.belief(consumo(Medicina,_,_,MMM,SSS));
	.println("Actualizado consumo a min: ",MMM," seg: ",SSS);
    !tomarMedicina.

/* NADA QUE TOMAR */
+!tomarMedicina <- 
    .wait(10);
    !tomarMedicina.

+!aPorMedicina(Medicina,H,M,S): free[source(self)]<-
		.println("A por medicina");
    	-free[source(self)];
		!at(enfermera, fridge);
		.send(owner,achieve,cancelarMedicacion);
		open(fridge); // Change it by an internal operation similar to fridge.open
		.belief(medicPend(L));
		!cogerTodaMedicina(L);
		.abolish(medicPend(L));
		+medicPend([]);
		close(fridge);
		!comprobarHora(L,H,M,S);
		+free[source(self)].

+!aPorMedicina(Medicina,_,_,_): not free[source(self)]<-
		.println("Añadido ", Medicina, " a la lista").

+!cancelarMedicacion <-
	.print("Me prohiben ir a por la medicacion");
	.drop_intention(aPorMedicina(_,_,_,_));
	+free.

+!comprobarHora([Med|MedL],H,M,S) <- // Car es consumo(X,T,H,M,S) 
		!at(enfermera, owner);	
		.time(HH,MM,SS);
		if(SS<S) { // where vl(X) is a belief    4 58    
			.print("Esperando a la hora perfecta... Hora perfecta: ",H,":",M,":",S);
			.print("Esperando en hora actual: ",HH,":",MM,":",SS);
       		!at(enfermera, owner);	
			!comprobarHora([Med|MedL],H,M,S);
     	}else{
			!darMedicina([Med|MedL],H,M,S);
			!enviarMedicinaPendiente;
		}.

+!enviarMedicinaPendiente: medicPend(L) <-
	.send(owner,achieve,medicinaRecibida(L)).

+!darMedicina([],H,M,S) <-
	.println("TODA LA MEDICINA TOMADA").

+!darMedicina([Med|MedL],H,M,S) <-
	.time(HH,MM,SS);
	.println("Dando al owner la medicina: ", Med, " a la hora: H:",HH,":",MM,":",SS);
	!darMedicina(MedL,H,M,S).

+!addMedicina(Medicina): medicPend(Med) <-
	.concat(Med,[Medicina],L);
	-medicPend(_);
	+medicPend(L).

+!cogerTodaMedicina([Car|Cdr]) <-
		.println("Cojo la medicina ",Car);
		getMedicina(Car);
		!cogerTodaMedicina(Cdr).

+!cogerTodaMedicina([]) <-
		.println("He cogido toda la medicina").

+!medicinaRecibida(L) <- 
	.println("Medicamentos actualizados");
	-medicPend(_);
	+medicPend(L).

+!at(Ag, P) : at(Ag, P) <- 
	.println(Ag, " is at ",P);
	.wait(500).
+!at(Ag, P) : not at(Ag, P) <- 
	//.println("Going to ", P, " <=======================");  
	.wait(200);
	!go(P);                                        
	//.println("Checking if is at ", P, " ============>");
	!at(Ag, P).            
	                                                   
+!go(P) : atRoom(RoomAg) & atRoom(P, RoomAg) <- 
	//.println("<================== 1 =====================>");
	//.println("Al estar en la misma habitación se debe mover directamente a: ", P);
	move_towards(P).  
+!go(P) : atRoom(RoomAg) & atRoom(P, RoomP) & not RoomAg == RoomP &
		  connect(RoomAg, RoomP, Door) & not atDoor(Door) <-
	//.println("<================== 3 =====================>");
	//.println("Al estar en una habitación contigua se mueve hacia la puerta: ", Door);
	move_towards(Door); 
	!go(P).                     
+!go(P) : atRoom(RoomAg) & atRoom(P, RoomP) & not RoomAg == RoomP &
		  connect(RoomAg, RoomP, Door) & not atDoor(Door) <- 
	//.println("<================== 3 =====================>");
	//.println("Al estar en la puerta de la habitación contigua se mueve hacia ", P);
	move_towards(P); 
	!go(P).       
+!go(P) : atRoom(RoomAg) & atRoom(P, RoomP) & not RoomAg == RoomP &
		  not connect(RoomAg, RoomP, _) & connect(RoomAg, Room, DoorR) &
		  connect(Room, RoomP, DoorP) & atDoor(DoorR) <-
	//.println("<================== 4 BIS =====================>");
	//.println("Se mueve a: ", DoorP, " para acceder a la habitación ", RoomP);
	move_towards(DoorP); 
	!go(P). 
+!go(P) : atRoom(RoomAg) & atRoom(P, RoomP) & not RoomAg == RoomP &
		  not connect(RoomAg, RoomP, _) & connect(RoomAg, Room, DoorR) &
		  connect(Room, RoomP, DoorP) & not atDoor(DoorR) <-
	//.println("<================== 4 =====================>");
	//.println("Se mueve a: ", DoorR, " para ir a la habitación contigua, ", Room);
	move_towards(DoorR); 
	!go(P). 
+!go(P) : atRoom(RoomAg) & atRoom(P, RoomP) & not RoomAg == RoomP <- //& not atDoor <-
	//.println("Owner is at ", RoomAg,", that is not a contiguous room to ", RoomP);
	//.println("<================== 5 =====================>");
	move_towards(P).                                                          
-!go(P) <- 
	.println("¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿ WHAT A FUCK !!!!!!!!!!!!!!!!!!!!");
	.println("..........SOMETHING GOES WRONG......").                                        
	                                                                        

                                     
+?time(T) : true
  <-  time.check(T).

