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
|	[UID_517222346] [Client-Side] [1] Non-kindOf Instance occypying a name(✅)                                                 	|	1.517          	|	1.517          	|
|	[UID_517222346] [Client-Side] [2] Name not registered warn(✅)                                                             	|	4.483          	|	2.967          	|
|	[UID_517222346] [Client-Side] [3.0] Creating Remote of all kinds with a taken name(✅)                                     	|	5.417          	|	0.933          	|
|	[UID_517222346] [Client-Side] [3.1] Public ["Remote"] field and Private ["_RI"] are the same Instance(✅)                  	|	5.417          	|	0.000          	|
|	[UID_517222346] [Client-Side] [4.0] Destruction empties objects(✅)                                                        	|	5.417          	|	0.000          	|
|	[UID_517222346] [Client-Side] [4.1] Destroyed objects error on read(✅)                                                    	|	5.417          	|	0.000          	|
|	[UID_517222346] [Client-Side] [4.2] Destroyed objects error on write(✅)                                                   	|	5.417          	|	0.000          	|
|	[UID_517222346] [Client-Side] [4.3] Destroying signal fires once(✅)                                                       	|	5.417          	|	0.000          	|
|	[UID_517222346] [Client-Side] [5] Error creating unnamed(✅)                                                               	|	5.417          	|	0.000          	|
|	[6.0] Client->Server (Connect, Once, Wait) over RemoteEvents(✅)                                                           	|	5.483          	|	0.067          	|
|	[UID_517222346] [Client-Side] [6.1] Server->Client (Connect, Once, Wait; "OnClientEvent" Included) over RemoteEvents(✅)   	|	5.517          	|	0.033          	|
|	[UID_517222346] [Client-Side] [6.2] Server->Client ":Once() and :Wait() truly fire only ONE TIME; :Connect() MULTIPLE"(✅) 	|	5.817          	|	0.300          	|
|	[6.3] Client->Server (Connect, Once, Wait with "OnServerEvent") over RemoteEvents(✅)                                      	|	5.833          	|	0.017          	|
|	[6.4] Client->Server ":Once() and :Wait() truly fire only ONE TIME; :Connect() MULTIPLE"(✅)                               	|	6.150          	|	0.317          	|
|	[6.5] Connection:Disconnect() works properly(✅)                                                                           	|	6.817          	|	0.667          	|
|	[6.6] RemoteEventBaseClass:Disconnect() works properly (disconnects all connections)(✅)                                   	|	7.633          	|	0.817          	|
|	[6.7] :SetCooldown() is safe (defaults to 0) and the cooldown implementation works as intended(✅)                         	|	15.750         	|	8.117          	|
|	[7.0] Writing/Reading Invoke Callback works as intended(✅)                                                                	|	15.750         	|	0.000          	|
|	[UID_517222346] [Client-Side] [7.1] Writing/Reading Invoke Callback works as intended(✅)                                  	|	16.083         	|	0.333          	|
|	[UID_517222346] [Client-Side] [7.2] :InvokeServer works as intended w/ cooldowns and RFER Messages(✅)                     	|	17.233         	|	1.150          	|
|	[7.3] :InvokeClient works as intended w/ RFER Messages(✅)                                                                 	|	18.283         	|	1.050          	|
|	[8] CoffeeRemotesClient Errors on require by Server-Sided script(✅)                                                       	|	18.283         	|	0.000          	|
|	[UID_517222346] [Client-Side] [8] CoffeeRemotesServer Errors on require by Client-Sided script(✅)                         	|	19.250         	|	0.967          	|
|	[9] Public API fields ["Remote"] and ["Destroying"] are Read-Only (Error on Write)(✅)                                     	|	19.250         	|	0.000          	|
|	[UID_517222346] [Client-Side] [9] Public API fields ["Remote"] and ["Destroying"] are Read-Only (Error on Write)(✅)       	|	21.167         	|	1.917          	|
|	[10.0] Not passing a Player as first argument to FireClient and InvokeClient methods errors(✅)                            	|	21.167         	|	0.000          	|
|	[10.1] Setting invalid values to OnInvoke \| OnServerInvoke fields outputs a warning and ignores the write(✅)             	|	21.167         	|	0.000          	|
|	[UID_517222346] [Client-Side] [10.2] Writing invalid values to OnInvoke \| OnClientInvoke fields -> warn + ignore write(✅)	|	21.217         	|	0.050          	|
|	[UID_517222346] [Client-Side] [10.3] Sending Tables with Cycle Table References yields errors(✅)                          	|	21.217         	|	0.000          	|
|	[UID_517222346] [Client-Side] [10.4] Client-Side GetRemote is safe(✅)                                                     	|	22.167         	|	0.950          	|
|	[11] mkdir is safe when re-requiring (no new Folders created)(✅)                                                          	|	22.167         	|	0.000          	|
|	[12] mkdir is safe (at startup with spoofed Folders)(✅)                                                                   	|	22.167         	|	0.000          	|
#  [CRR Test]: Test PASSED ✅✅✅!