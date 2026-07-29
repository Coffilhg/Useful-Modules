#  [CRR Test]: Test complete! PASS ✅ = 41; FAIL ❌ = 0
#  [CRR Test]: Test Timestamps: 
|	[ CoffeeRemotesRefined ] Test Name (✅/❌)                                                                                  	|	Absolute time()	|	Relative time()	|
|--------------------------------------------------------------------------------------------------------------------------------|-----------------|-----------------|
|	Script Started (✅)                                                                                                        	|	0.000          	|	none           	|
|	[1] Non-kindOf Instance occypying a name(✅)                                                                               	|	0.000          	|	0.000          	|
|	[1.1] Name taken by non-Object tied Instance of appropriate kind(✅)                                                       	|	0.000          	|	0.000          	|
|	[2] Creating Remote of all kinds with the same name(✅)                                                                    	|	0.000          	|	0.000          	|
|	[3] Creating Remote of all kinds with a taken name(✅)                                                                     	|	0.000          	|	0.000          	|
|	[4.0] Destruction empties objects(✅)                                                                                      	|	0.000          	|	0.000          	|
|	[4.1] Destroyed objects error on read(✅)                                                                                  	|	0.000          	|	0.000          	|
|	[4.2] Destroyed objects error on write(✅)                                                                                 	|	0.000          	|	0.000          	|
|	[4.3] Destroying signal fires once(✅)                                                                                     	|	0.000          	|	0.000          	|
|	[5] Error creating unnamed(✅)                                                                                             	|	0.000          	|	0.000          	|
|	[UID_517222346] [Client-Side] [1] Non-kindOf Instance occypying a name(✅)                                                 	|	0.433          	|	0.433          	|
|	[UID_517222346] [Client-Side] [2] Name not registered warn(✅)                                                             	|	2.533          	|	2.100          	|
|	[UID_517222346] [Client-Side] [3.0] Creating Remote of all kinds with a taken name(✅)                                     	|	3.483          	|	0.950          	|
|	[UID_517222346] [Client-Side] [3.1] Public ["Remote"] field and Private ["_RI"] are the same Instance(✅)                  	|	3.483          	|	0.000          	|
|	[UID_517222346] [Client-Side] [4.0] Destruction empties objects(✅)                                                        	|	3.483          	|	0.000          	|
|	[UID_517222346] [Client-Side] [4.1] Destroyed objects error on read(✅)                                                    	|	3.483          	|	0.000          	|
|	[UID_517222346] [Client-Side] [4.2] Destroyed objects error on write(✅)                                                   	|	3.483          	|	0.000          	|
|	[UID_517222346] [Client-Side] [4.3] Destroying signal fires once(✅)                                                       	|	3.483          	|	0.000          	|
|	[UID_517222346] [Client-Side] [5] Error creating unnamed(✅)                                                               	|	3.483          	|	0.000          	|
|	[6.0] Client->Server (Connect, Once, Wait) over RemoteEvents(✅)                                                           	|	3.546          	|	0.063          	|
|	[UID_517222346] [Client-Side] [6.1] Server->Client (Connect, Once, Wait; "OnClientEvent" Included) over RemoteEvents(✅)   	|	3.588          	|	0.042          	|
|	[UID_517222346] [Client-Side] [6.2] Server->Client ":Once() and :Wait() truly fire only ONE TIME; :Connect() MULTIPLE"(✅) 	|	3.900          	|	0.313          	|
|	[6.3] Client->Server (Connect, Once, Wait with "OnServerEvent") over RemoteEvents(✅)                                      	|	3.917          	|	0.017          	|
|	[6.4] Client->Server ":Once() and :Wait() truly fire only ONE TIME; :Connect() MULTIPLE"(✅)                               	|	4.233          	|	0.317          	|
|	[6.5] Connection:Disconnect() works properly(✅)                                                                           	|	4.879          	|	0.646          	|
|	[6.6] RemoteEventBaseClass:Disconnect() works properly (disconnects all connections)(✅)                                   	|	5.696          	|	0.817          	|
|	[6.7] :SetCooldown() is safe (defaults to 0) and the cooldown implementation works as intended(✅)                         	|	13.800         	|	8.104          	|
|	[7.0] Writing/Reading Invoke Callback works as intended(✅)                                                                	|	13.800         	|	0.000          	|
|	[UID_517222346] [Client-Side] [7.1] Writing/Reading Invoke Callback works as intended(✅)                                  	|	14.150         	|	0.350          	|
|	[UID_517222346] [Client-Side] [7.2] :InvokeServer works as intended w/ cooldowns and RFER Messages(✅)                     	|	15.300         	|	1.150          	|
|	[7.3] :InvokeClient works as intended w/ RFER Messages(✅)                                                                 	|	16.363         	|	1.063          	|
|	[8] CoffeeRemotesClient Errors on require by Server-Sided script(✅)                                                       	|	16.363         	|	0.000          	|
|	[UID_517222346] [Client-Side] [8] CoffeeRemotesServer Errors on require by Client-Sided script(✅)                         	|	17.346         	|	0.983          	|
|	[9] Public API fields ["Remote"] and ["Destroying"] are Read-Only (Error on Write)(✅)                                     	|	17.346         	|	0.000          	|
|	[UID_517222346] [Client-Side] [9] Public API fields ["Remote"] and ["Destroying"] are Read-Only (Error on Write)(✅)       	|	19.250         	|	1.904          	|
|	[10.0] Not passing a Player as first argument to FireClient and InvokeClient methods errors(✅)                            	|	19.250         	|	0.000          	|
|	[10.1] Setting invalid values to OnInvoke \| OnServerInvoke fields outputs a warning and ignores the write(✅)             	|	19.250         	|	0.000          	|
|	[UID_517222346] [Client-Side] [10.2] Writing invalid values to OnInvoke \| OnClientInvoke fields -> warn + ignore write(✅)	|	19.296         	|	0.046          	|
|	[UID_517222346] [Client-Side] [10.3] Sending Tables with Cycle Table References yields errors(✅)                          	|	19.296         	|	0.000          	|
|	[UID_517222346] [Client-Side] [10.4] Client-Side GetRemote is safe(✅)                                                     	|	20.250         	|	0.954          	|
|	[11] mkdir is safe when re-requiring (no new Folders created)(✅)                                                          	|	20.250         	|	0.000          	|
|	[12] mkdir is safe (at startup with spoofed Folders)(✅)                                                                   	|	20.250         	|	0.000          	|
#  [CRR Test]: Test PASSED ✅✅✅!