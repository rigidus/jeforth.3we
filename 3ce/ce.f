
\ jeforth.3ce for Google Chrome extension 
\ chrome.* APIs http://chrome-apps-doc2.appspot.com/trunk/extensions/api_index.html

s" ce.f" source-code-header

\
\ Skip everything if is not running in Chrome extension.
\
js> typeof(chrome)!='undefined'&&typeof(chrome.runtime)!='undefined' [if] \ Chrome extension environment.

	\
	\ Setup the Background page 
	\ which is the common part of the 3ce isolated world.
	\
	js> chrome.extension.getBackgroundPage() value background-page // ( -- window ) Get the background page's window object.
<comment>
	background-page :> jeforth_project_k_virtual_machine_object 
	[if] 
		\ 不能重複 init background page
		\ 因為 background page 一直都在, popup & 3ce extension page can have multiple instances.
		\ 如果每個 instance 都來 init background page 會怎樣?
		\ 若要重複 init 只要 jeforth_project_k_virtual_machine_object=null 然後 refresh 
		\ 3ce ext page 即可。 
	[else] 
	
	    \ include jQuery
		background-page :> document.createElement("script")  ( [object HTMLScriptElement] )
		dup :: setAttribute("src","js/jquery-1.10.2.js")    ( [object HTMLScriptElement] )
		background-page :> document.getElementsByTagName('head')[0] :: appendChild(pop())
		
	    \ include project-k kernel jeforth.js 
		background-page :> document.createElement("script")  ( [object HTMLScriptElement] )
		dup :: setAttribute("src","project-k/jeforth.js")    ( [object HTMLScriptElement] )
		background-page :> document.getElementsByTagName('head')[0] :: appendChild(pop())
		
		\ init jeforth VM
		background-page <js> pop().jeforth_project_k_virtual_machine_object = new jeForth()</jsV> \ TOS
		background-page :: vm=pop()
		background-page <js>
			(function(backgroundPage){
				// 這時候是在 host page (可以是任何一個 3ce extension page 或 the popup page) 
				// 幫 background page setup jeforth, 所以都要冠以 bg.vm.something. 到了 background 
				// page 本身時 scripts 當然只需自稱 vm 即可。
				var bg = backgroundPage;
				bg.vm.minor_version = 1; // minor version specified by each application (like here), major version is from jeforth.js kernel.
				var version = parseFloat(bg.vm.major_version+"."+bg.vm.minor_version);
				bg.vm.appname = "jeforth.3ce.backgroundpage"; //  不要動， jeforth.3we kernel 用來分辨不同 application。
				bg.vm.host = bg; // DOM window is the root for 3HTM. global 掛那裡的根據。
				bg.vm.path = ["dummy", "doc", "f", "3htm/f", "3htm/canvas", "3htm", "3ce", "playground"];
				bg.vm.screenbuffer = ""; // type() to screenbuffer before I/O ready; self-test needs it too.
				bg.vm.selftest_visible = true; // type() refers to it.
				bg.vm.debug = false;
				bg.vm.prompt = "OK";
				bg.vm.bye = function(){bg.close()}; // Does this work? [ ] background page 應該是關不掉的。
				bg.vm.clearScreen = function(){ bg.vm.screenbuffer = ""; }
				
				bg.vm.type = function (s) {
					var ss;
					try {
						ss = s + ''; // Print-able test
					} catch(err) {
						ss = Object.prototype.toString.apply(s);
					}
					bg.vm.screenbuffer += ss;
				};
				
				bg.vm.panic = function(state) {
					bg.vm.type(state.msg);
					if (state.serious) debugger;
				};
				
				bg.vm.greeting = function(){
					bg.vm.type("j e f o r t h . 3 c e (background page) -- v"+version+'\n');
					bg.vm.type("source code http://github.com/hcchengithub/jeforth.3we\n");
					bg.vm.type("Program path " + bg.window.location.toString());
					return(version);
				}
				
			})(pop());
		</js>
		
		\ include jeforth.f
		char f/jeforth.f         readTextFile ( file ) background-page :: vm.dictate(pop()) 
		\ include readtextfile.f
		char 3htm/f/readtextfile.f    readTextFile ( file ) background-page :: vm.dictate(pop()) 
		
	[then]
</comment>
	: open-3ce-tab ( -- ) \ Open a jeforth.3ce tab.
		js> window.open("index.html") background-page :: lastTab=pop() ;
		
	: tabs.getCurrent ( -- objTab ) \ Get the current tab object.
		js: chrome.tabs.getCurrent(function(tab){push(tab);execute('stopSleeping')}) 
		1000 sleep ;
		/// Used in an extension page or content script in target pages. 
		/// Returns 'undefined' if used in the popup page or background page.

	tabs.getCurrent [if] [else]
		\
		\ In Chrome extension/app is sure.
		\ Initial Chrome extension popup page appearance. The font size better be smaller.
		\
	\   js:	$("#body")[0].style.width="100%"; \ 不如 660px 大
		js:	$("#body")[0].style.width="660px"; 
		js:	$("#header")[0].style.fontSize="0.6em"; 
		js:	$("#outputbox")[0].style.fontSize="0.8em";
	[then]

	: tabs.query ( {title:"*anual*"} -- array ) \ Get an array of tabs that match the given hash.
		<js> chrome.tabs.query(pop(),function(tabs){
			push(tabs);
			execute('stopSleeping')
		})</js> 10000 sleep ;
		/// The input is a hash table, like :
		/// {} tabs.query -- get all tabs.
		/// js: push({active:true}) tabs.query -- get active tabs of every window.
		/// js: push({title:"*anual*"}) tabs.query -- title pattern supports wildcard character '*'.
		/// js: push({url:"http://*ibm*/*"}) tabs.query -- url pattern supports wildcard too.
		/// <scheme>://<host><path> see http://chrome-apps-doc2.appspot.com/trunk/extensions/match_patterns.html
		/// Should return an array, 'undefined' indicates invalid pattern.
		
	: list-tabs ( -- ) \ List Tabs in the current window
		{} tabs.query ( array ) dup :> length ( array length )
		?dup if for ( array )
		r@ 1- js> tos(1) :> [pop()] ( array tab )
		dup :> id . space ( array tab )
		:> title . cr ( array )
		next drop then ;
		/// {} tabs.query (see) to see them in details.

	: tabid ( -- tabid ) \ The working tab's id.
		background-page :> workingTabId ;
	 
	: tabid! ( tabid -- ) \ Set working tab id.
		background-page :: workingTabId=pop() ;
	: tabs.get ( tabid -- tabObj ) \ Get the specified tab object.
		<js> chrome.tabs.get(pop(),function(tab){
			push(tab);
			execute('stopSleeping')
		})</js> 10000 sleep ;

	: tabs.select ( -- ) \ Set ce.f's working tabid. 
		begin 
			<js> alert("Select the working Chrome tab in 3 seconds, ready?")</js>
			3000 nap
			js: push({active:true}) tabs.query ( array )
			dup :> length 1 > ?abort" You have multiple Chrome windows, one only please."
			:> [0].id tabid! 
			s" It's '" tabid tabs.get :> title + s" ' right?" +
			js> confirm(pop()) 
		until ;
		/// Sometimes we can't use "the active tab" as the working tab 
		/// because it is the 3ce page. BTW, to get the active tab:
		/// js: push({active:true}) tabs.query js> tos().length \ ==> 1 (number)
		
	: get-manifest ( -- obj ) \ Get the Chrome extension/app manifest hash table.
		js> chrome.runtime.getManifest() ;
		
	: see-manifest ( -- ) \ See the Chrome extension/app manifest hash table.
		get-manifest js> JSON.stringify(pop(),"\n","\t") . ;
		
	: inject ( pathname -- result ) \ Inject a JavaScript file to tabid
		tabid <js> chrome.tabs.executeScript(pop(), {file:pop()}, 
		function(result){push(result);execute('stopSleeping')}) </js> 
		120000 sleep ;
		/// Have content script to include project-k:
		/// > char project-k/jeforth.js indect drop 
		/// The CallBack returns an array which is "The result of the script in every injected frame."
		/// A result is the value of the last statement of the script file.
		/// In case of project-k it returns an array: ["uses strict"].
		/// In case of 3ce/background.js it returns an array: [null].
		
	: <ce> ( <js statements> -- "block" ) \ Get JavaScript statements
		char </ce>|</ceV> word ; immediate
		/// chrome.tabs.executeScript() 不能用在 3ce 自己的 Extension pages。
		/// 必須是【別人的】web page。

	code (/ce) ( "statements" -- ) \ No return value
		execute('tabid');
		chrome.tabs.executeScript(pop(),{"code": pop()}); 
		end-code

	: </ce> ( "statements" -- ) \ Execute 3ce statements on target tabid. No return value.
		compiling if literal compile (/ce) else (/ce) then ; immediate

	: (/ceV) ( "statements" -- ) \ Retrun the value of last statement
		tabid <js> chrome.tabs.executeScript(pop(),{"code": pop()},
		function(result){push(result);execute('stopSleeping')}) </js> 
		50000 sleep ;
		/// chrome.tabs.executeScript() 不能用在 3ce 自己的 Extension pages。

	: </ceV> ( "statements" -- ) \ Execute 3ce statements on target tabid. Retrun the value of last statement
		compiling if literal compile (/ceV) else (/ceV) then ; immediate

	\
	\ Host side setup to receiving messages (forth commands) from content scripts
	\ Extension page <==> Content Script or Target page 之間雙向的 message 都是 
	\ 3ce SPEC of sendMessage({forth:".s",type:"hello world!",tos:anything})
	\
		\ Host side Chrome extension handler that receives messages from content scripts on target pages.
		<js>
		    // Host side onMessage event hander 
			chrome.runtime.onMessage.addListener(
				function ce3_host_onmessage (message, sender, sendResponse) { 
				    // see "3ce SPEC of sendMessage"
					if (message.forth) {
						dictate(message.forth);
					}
					if (message.type) {
						vm.type(message.type);
						window.scrollTo(0,endofinputbox.offsetTop);inputbox.focus(); // Host side
					} 
					if (message.tos) {
						push(message.tos);
					} 
				}
			)
		</js> 
		
	code message->tabid ( anything -- ) \ Send a message of anything to tabid
		execute("tabid"); chrome.tabs.sendMessage(pop(),pop()) end-code
		/// Usage: anything message->tabid
		
	: (dictate) ( "forth source code" -- ) \ Run a block of forth source code on tabid.
		js: push({forth:pop()}) message->tabid ;
		/// Usage: <text> ... </text> (dictate)
		
	code {F7} ( -- ) \ Send inputbox to content script of tabid.
		vm.cmdhistory.push(inputbox.value);  // Share the same command history with the host
		push(inputbox.value); // command line 
		inputbox.value=""; // clear the inputbox
		execute("(dictate)"); // Let target page the execute the command line(s)
		push(false); // terminiate event bubbling
		end-code
		/// 若用 F8 則無效, 猜測是 Chrome debugger 自己要用。
		
	: (install) ( "pathname" -- ) \ Install forth source code to tabid.
		readTextFileAuto char shooo! swap + (dictate) ;
		/// shooo! avoid echoing the entire source code.
	
	: install ( <pathname> -- )  \ Install forth source code to tabid.
		char \n|\r word (install) ;

	: first-tab ( -- objTab ) \ Get first tab (the leftest) of Chrome browser.
		js: push({"index":0}) tabs.query :> [0] ;
		/// Uncertain which 'leftest tab' if there're multiple Chrome windows.
		
	: active-tab  ( -- objTab ) \ Get the active tab of Chrome browser.
		js: push({active:true}) tabs.query :> [0] ;
		/// Used by 3ce popup page.

	: attach ( -- ) \ Attach 3ce to the active tab.
		\ Specify the tab to attach
		  active-tab :> id tabid!
		\ Wait for the target page to be loaded
		  500 nap active-tab :> status!="complete" if  
			." Still loading " active-tab :> title . space
			0 begin
				active-tab :> status=="complete" if 1+ then
				dup 5 > if else \ 5 complete to make sure it's very ready.
					js: window.scrollTo(0,endofinputbox.offsetTop);inputbox.focus();
					char . . 300 nap false
				then 
			until
		  then 
		\ Install jQuery and project-k to target tab.
		<ce> typeof(jeForth)</ceV> char function != if 	
			char js/jquery-1.11.2.js inject drop			
		then
		char project-k/jeforth.js inject drop 
		
		\ Install the main program of jeforrth.3ce (jeforth.3htm.js equivalent)
		<ce>
			var jeforth_project_k_virtual_machine_object = new jeForth(); // A permanent name.
			var vm = jeforth_project_k_virtual_machine_object; // "vm" may not be so permanent.
			// vm is now the jeforth virtual machine object. It has no idea about the outside world
			// that can be variant applications: HTML, HTA, Node.js, Node-webkit, .. etc.
			// We need to help it a little as the following example:
			
			(function(){
				vm.minor_version = 1; // minor version specified by each application (like here), major version is from jeforth.js kernel.
				var version = vm.version = parseFloat(vm.major_version+"."+vm.minor_version);
				vm.appname = "jeforth.3ce"; //  不要動， jeforth.3we kernel 用來分辨不同 application。
				vm.host = window; // DOM window is the root for 3HTM. global 掛那裡的根據。
				vm.path = ["dummy", "doc", "f", "3htm/f", "3htm/canvas", "3htm", "3ce", "playground"];
				vm.screenbuffer = ""; // type() to screenbuffer before I/O ready; self-test needs it too.
				vm.selftest_visible = true; // type() refers to it.
				vm.debug = false;

				// Message (or F7 forth command line) from the host page needs an event handler
				function target_f7_handler (message, sender, sendResponse) { 
					// see "3ce SPEC of sendMessage"
					// 先收 data
					if (message.tos!=undefined) { // Can be "" when readTextFile failed
						vm.push(message.tos);
					} 
					// 再執行命令
					if (message.forth) {
						vm.forthConsoleHandler(message.forth);
					}
				}
				// Avoid multiple registration of the same handler.
				if (!chrome.runtime.onMessage.hasListeners()) 
					chrome.runtime.onMessage.addListener(target_f7_handler);
				
				// I/O  
				// Forth vm doesn't know how to 'type'. We need teach it by defining the vm.type().
				// vm.type() is the only mandatory I/O jeforth VM needs to know. 
				vm.type = function (s) {
					try {
						var ss = s + ''; // Print-able test
					} catch(err) {
						ss = Object.prototype.toString.apply(s);
					}
					if(vm.screenbuffer!=null) vm.screenbuffer += ss; // 填 null 就可以關掉。
					if(vm.selftest_visible) chrome.runtime.sendMessage({type:s});
				};
				
				// vm.panic() is the master panic handler. The panic() function defined in 
				// project-k kernel jeforth.js is the one called in code ... end-code.
				vm.panic = function(state){ 
					vm.type(state.msg);
					if (state.serious) debugger;
				}
				// We need the panic() function below but we can't see the one in jeforth.js
				// so one is defined here for convenience.
				function panic(msg,level) {
					var state = {
							msg:msg, level:level
						};
					if(vm.panic) vm.panic(state);
				}
				
				vm.clearScreen = function () {
					vm.screenbuffer = "";
					$('#outputbox').empty();
				}
				
				// The Forth traditional prompt 'OK' is defined and used in this application main program.
				// Forth vm has no idea about vm.prompt but your program may want to know.
				// In that case, as an example, use vm property to store the vm global variables and functions.
				vm.prompt = "OK";
	
				vm.forthConsoleHandler = function(cmd) {
					var rlwas = vm.rstack().length; // r)stack l)ength was
					// Avoid responding the ~.f source code when installing.
					if(cmd.indexOf("shooo!")!=0)
						vm.type((cmd?'\n> ':"")+cmd+'\n');
					else
						cmd = cmd.slice(6); // remove "shooo!"
					vm.dictate(cmd);  // Pass the command line to jeForth VM
					(function retry(){
						// rstack 平衡表示這次 command line 都完成了，這才打 'OK'。
						// event handler 從 idle 上手，又回到 idle 不會讓別人看到它的 rstack。
						// 雖然未 OK, 仍然可以 key in 新的 command line 且立即執行。
						if(vm.rstack().length!=rlwas)
							setTimeout(retry,100); 
						else {
							vm.type(" " + vm.prompt + " ");
							if (typeof(endofinputbox)!="undefined"){
								if ($(inputbox).is(":focus"))
									window.scrollTo(0,endofinputbox.offsetTop);
							}
						}
					})();
				}
				
				// Take care of HTML special characters
				var plain = vm.plain = function (s) {
					var ss = s + ""; // avoid numbers to fail at s.replace()
					ss = ss.replace(/\t/g,' &nbsp; &nbsp;');
					ss = ss.replace(/ /g,'&nbsp;');
					ss = ss.replace(/</g,'&lt;');
					ss = ss.replace(/>/g,'&gt;');
					ss = ss.replace(/\n/g,'<br>');
					return ss;
				}
	
				vm.greeting = function(){
					vm.type("j e f o r t h . 3 c e -- v"+version+'\n');
					vm.type("source code http://github.com/hcchengithub/jeforth.3we\n");
					return(version);
				}
				
				vm.bye = function(){window.close()};
				
				// Called from jsEvalRaw, it will handle the try{}catch{} thing. 
				vm.writeTextFile = function(pathname,data) { // Write string to text file.
					panic("Error writing " + pathname + ", jeforth.3ce doesn't know how to wrtieTextFile yet.\n"); 
				}
	
				vm.readTextFile = function(pathname){
					panic("jeforth.3ce does not have vm.readTextFile(), please use readTextFile directly.\n");
				}
			})();
		</ceV>  drop \ Use /ceV for synchronous
		char f/jeforth.f (install)
		<text> shooo!
			: readTextFile ( "pathname" -- "text" ) \ Read text file from jeforth.3ce host page.
				s" s' " swap + s" ' readTextFile " + \ command line 以下讓 Extention page (the host page) 執行
				s" {} js: tos().forth='shooo!stopSleeping';tos().tos=pop(1) " + \ host side packing the message object
				s" message->tabid " + \ host commands after resume from file I/O
				js: chrome.runtime.sendMessage({forth:pop()}) \ dictate host page to execute the above statements.
				10000 sleep ;   
		</text> (dictate)
		\ [ ] 不能放上面直接用 include quit.f 原因待查 <-- try attach3
		char 3ce/quit.f	(install) 
		;

[then] \ Not Chrome extension environment.

				
	
	