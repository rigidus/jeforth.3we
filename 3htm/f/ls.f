
	\ Maintain source code in HTML5 local storage directly

	s" ls.f"		source-code-header
	
	: (eb.parent) ( node -- eb ) \ Get the parent edit box object of the given node/element.
		js> $(pop()).parents('.eb')[0] ( eb ) ;

	: eb.edit ( btn -- ) \ Make the textarea and the name editable.
		(eb.parent) ( eb ) \ The input object can be any node of the editbox.
		js: $('.ebname',tos())[0].contentEditable=true
		js: $('textarea',pop())[0].readOnly=false ;
		
	: eb.readonly ( btn -- ) \  Make the textarea and the name read-only.
		(eb.parent) ( eb ) \ The input object can be any node of the editbox.
		js: $('.ebname',tos())[0].contentEditable=false
		js: $('textarea',pop())[0].readOnly=true ;

	: eb.save ( btn -- ) \ Save the textarea to localStorate[name].
		(eb.parent) ( eb ) \ The input object can be any node of the editbox.
		js> $('.ebname',tos())[0].innerText trim ( eb name )
		js> $('textarea',tos(1))[0].value ( eb name text )
		js: storage.set(pop(1),pop()) ( eb )
		js: $('.ebsave',pop())[0].value="Saved" ;
		
	: (eb.read) ( eb field_name -- ) \  Read the localStorate[name] to textarea of the given edit box.
		js> storage.get(tos())  ( eb name text|undefined ) 
		js> tos()==undefined if  ( eb name text|undefined ) 
			<js> alert("Error! can't find '" + pop(1) + "' in local storage.")</js>
			2drop exit
		then  nip ( eb text )
		js> $('.ebsave',tos(1))[0].value=="Save" if  ( eb text )
			<js> confirm("Unsaved local storage edit box will be overwritten, are you sure?") </jsV> 
			if else 2drop exit then
		then  ( eb text )
		js: $('textarea',tos(1))[0].value=pop()
		js: $('.ebsave',pop())[0].value="Saved" ;
	
	: eb.read ( btn -- ) \ Read the localStorate[name] to textarea.
		(eb.parent) ( eb ) \ The input object can be any node of the editbox.
		js> $('.ebname',tos())[0].innerText trim ( eb name ) (eb.read) ;
		
	: eb.close ( btn -- ) \ Close the local storage edit box to stop editing.
		(eb.parent) ( eb ) \ The input object can be any node of the editbox.
		js> $('.ebsave',tos())[0].value=="Save" if 
			<js> confirm("Are you sure you want to clsoe the unsaved local storage edit box?") </jsV> 
			if else exit then
		then ( eb ) removeElement ;

	: eb.delete ( btn -- ) \ Delete the local storage edit box and the local storage field.
		(eb.parent) ( eb ) \ The input object can be any node of the editbox.
		<js> $('textarea',tos())[0].value.indexOf("delete me no regret")!=0</jsV>
		if <js> alert('Place "delete me no regret" at the very beginning of the textarea to demonstrate yor guts.') </js> drop exit then
		js> $('.ebname',tos())[0].innerText trim ( eb name ) 
		js: storage.del(pop()) ( eb ) removeElement ;

	: eb.run ( btn -- ) \ Run FORTH source code of the local storage edit box.
		(eb.parent) ( eb ) \ The input object can be any node of the editbox.
		js: dictate($('textarea',pop())[0].value) ;
		
	: eb.onchange ( btn -- ) \ Event handler on local storage edit box has changed
		(eb.parent) ( eb ) \ The input object can be any node of the editbox.
		<js> $(".ebsave",pop())[0].value="Don't forget to SAVE !"</js> ;

	: init-buttons ( eb -- eb ) \ Initialize buttons of the local storage edit box.
		<js> $(".ebsave",    tos())[0].onclick =function(e){push(this);execute("eb.save");    return(false)}</js>
		<js> $(".ebread",    tos())[0].onclick =function(e){push(this);execute("eb.read");    return(false)}</js>
		<js> $(".ebedit",    tos())[0].onclick =function(e){push(this);execute("eb.edit");    return(false)}</js>
		<js> $(".ebreadonly",tos())[0].onclick =function(e){push(this);execute("eb.readonly");return(false)}</js>
		<js> $(".ebclose",   tos())[0].onclick =function(e){push(this);execute("eb.close");   return(false)}</js>
		<js> $(".ebrun",     tos())[0].onclick =function(e){push(this);execute("eb.run");     return(false)}</js> 
		<js> $(".ebdelete",  tos())[0].onclick =function(e){push(this);execute("eb.delete");  return(false)}</js> 
		<js> $(".ebtextarea",tos())[0].onchange=function(e){push(this);execute("eb.onchange");return(false)}</js> 
		<js> 
			$(".ebtextarea",tos())[0].onkeydown = function(e) {
				e = (e) ? e : event; 
				var keycode = (e.keyCode) ? e.keyCode : (e.which) ? e.which : false;
				switch(keycode) {
					case  83: /* s */
						if (e&&e.ctrlKey) {
							push(this); // ( textarea ) 
							execute("eb.save");
							var temp=this.value;this.value="";this.value=temp; // Saved already so clear the onchange status
							e.stopPropagation ? e.stopPropagation() : (e.cancelBubble=true); // stop bubbling
							return(false);
						}
					default: return (true); // pass down to following handlers
				}
			}
		</js> ;

	: (ed) ( -- edit_box_element ) \ Create an HTML5 local storage edit box in outputbox
		<text> <div class=eb style="width:90%;border:1px solid black;">
			<p style="display:inline;">Local Storage Field </p>
			<p class=ebname style="display:inline;padding-left:2px;font-size:1.2em;border:0.75px solid gray;" contentEditable> Edit field name </p>
			<p style="display:inline;">
			<input type=button value='Saved' class=ebsave>
			<input type=button value='Read' class=ebread>
			<input type=button value='Edit' class=ebedit>
			<input type=button value='Delete' class=ebdelete>
			<input type=button value='Read only' class=ebreadonly>
			<input type=button value='Close' class=ebclose>
			<input type=button value='Run' class=ebrun></p>
			<textarea class=ebtextarea style="margin-top:1em;" rows=20 wrap="off"></textarea>
		</div></text> 
		:> replace(/[/]\*(.|\r|\n)*?\*[/]/mg,"") \ clean /* comments */ 
		</o> ( eb ) js: window.scrollTo(0,tos().offsetTop-50) ( eb )
		init-buttons ;
	
	: ed (ed) drop ; // ( -- ) Create an HTML5 local storage edit box in outputbox
	
	: autoexec ( -- ) \ Run localStorage.autoexec
		js> storage.get("autoexec") js> tos() if  ( autoexec )
			tib.insert
		then ;

	: (run)  ( "local storage field name" -- ) \ Run local storage source code.
		js> storage.get(pop()) tib.append ;
		
	: run ( <local storage field name> -- ) \ Run local storage source code.
		char \n|\r word trim (run) ;

	: cls  ( -- ) \ Clear all #text in the outputbox elements are remained.
		ce@ ( save ) js> outputbox ce! er ce! ( restore ) ;
		/// Auto save-restore ce@ so it won't be changed.
	
	: list ( -- ) \ List all localStorage fields, click to open
		<text> <unindent><br>
			Local storage field '<code>autoexec</code>' is run when start-up.
			'<code>run <field name></code>' to run the local storage field.
			'<code>ed</code>' opens local storage editor and when in this editor,
			hotkey <code>{F9},{F10}</code> resize the textarea and <code>{Ctrl-S}</code> saves
			the textarea to local storage.
			'<code>export-all</code>' exports the entire local storage in JSON format.
			<br><br>
		</unindent></text> <code>escape </o> drop
		js> storage.all() obj>keys ( array )
		begin js> tos().length while ( array )
			js> tos().pop()  ( array- fieldname )
			<text>
				<li> _fieldname_ 
				<input class=lsfieldopen fieldname='_fieldname_' type=button value=Open> 
				<input class=lsfieldexport fieldname='_fieldname_' type=button value=Export>
				</li>
			</text>	( array- fieldname HTML )
			:> replace(/_fieldname_/mg,pop()) </o> drop
		repeat drop cr
		<js> 
			$("input.lsfieldopen").click(function(){
				execute("(ed)"); 
				push(this.getAttribute("fieldname")); // ( eb name ) 
				$('.ebname',tos(1))[0].innerHTML=tos();
				execute("(eb.read)");
			})
			$("input.lsfieldexport").click(function(){
				push(null); // ( null ) 
				push(storage.get(this.getAttribute("fieldname"))); // ( null text ) 
				execute("(export)");
			})
		</js> ;
		
	: (export) ( null|window "text" -- ) \ Export the given text string to a window
		js> tos(1) if else nip js> window.open() swap then ( window "text" )
		js: pop(1).document.write("<html><body><pre>"+pop()+"</pre></body></html>") ;
		
	: export ( <field> -- ) \ Create a window to export a local storage field.
		null char \n|\r word trim js> storage.get(pop()) (export) ;
		
	: export-all ( -- ) \ Create a window to export entire local storage in JSON format.
		null js> JSON.stringify(storage.all(),"\n","\t") (export) ;
	
	\ Setup default autoexec, ad, and pruning if autoexec is not existing
	js> storage.get("autoexec") [if] [else] 
		<text> <unindent>
			js: outputbox.style.fontSize="1.5em"
			cr cr 
			." Hello world!! says 'autoexec' field" cr
			." from published jeforth.3ce. "
			cr cr 
			.( Launch the briefing ) cr
			<o> <iframe src="http://note.youdao.com/share/?id=79f8bd1b7d0a6174ff52e700dbadd1b2&type=note"
			name="An introduction to jeforth.3ce" align="center" width="96%" height="1000px"
			marginwidth="1" marginheight="1" frameborder="1" scrolling="Yes"> </iframe></o> drop
			cr cr 
			.( execute the 'list' command ) cr
			list
		</unindent></text> unindent js: storage.set("autoexec",pop())

 		js> storage.get("ad") [if] [else] \ Default ad if it's not existing
			<text> <unindent>
				\ Remove all annoying floating ad boxes. 刪除所有惱人的廣告框。
				active-tab :> id tabid! <ce>
				var divs = document.getElementsByTagName("div");
				for (var i=divs.length-1; i>=0; i--){
				  if(divs[i].style.position){
					divs[i].parentNode.removeChild(divs[i]);
				  }
				}
				for (var i=divs.length-1; i>=0; i--){
				  if(parseInt(divs[i].style.width)<600){ // <---- 任意修改
					divs[i].parentNode.removeChild(divs[i]);
				  }
				}
				</ce>
			</unindent></text> unindent js: storage.set("ad",pop())
		[then]

		js> storage.get("pruning") [if] [else] \ Default pruning if it's not existing
			<text> <unindent>
				\ Make the target page editable for pruning. 把 target page 搞成 editable 以便修剪。
				active-tab :> id tabid! <ce> document.getElementsByTagName("body")[0].contentEditable=true </ce>
			</unindent></text> unindent js: storage.set("pruning",pop())
		[then]
	[then]

	autoexec \ Run localStorage.autoexec when jeforth starting up
	
	
