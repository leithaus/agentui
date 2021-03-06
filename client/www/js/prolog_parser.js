// -*- mode: Javascript;-*- 
// Filename:    candidate_prolog_parser_in_js.js 
// Authors:     lgm                                                    
// Creation:    Thu Mar 13 11:41:47 2014 
// Copyright:   Not supplied 
// Description: 
// ------------------------------------------------------------------------

var prologParser = ( function() {
    // Object (of a style...) definitions:
	// Rule = (Head, Body)
	// Head = Term
	// Body = [Term]
	// Term = (id, Parameters)
	// Parameters {Partlist} = [Part]
	// Part = Variable | Atom | Term

	function Variable(head) {
		this.name = head;
		// I had a sneaking suspicion that the (rather nice, I reckon)
		// idiom below returned a closure-like reference rather than an
		// anonymous function reference. It does; but I'm not overly
		// concerned with efficiency here. This is is Prolog interpreter
		// written in JS, for goodness' sake!
		this.print = function () { print (this.name); };
		this.type = "Variable";
	}

	function Atom(head) {
		this.name = head;
		this.print = function () { print (this.name); };
		this.type = "Atom";
	}

	function Term(head, list) {
		this.name = head;
		this.partlist = new Partlist(list);
		this.print =
			function () {
				if (this.name == "cons") {
					var x = this;
					while (x.type == "Term" && x.name == "cons" && x.partlist.list.length == 2) {
						x = x.partlist.list[1];
					}
					if ((x.type == "Atom" && x.name == "nil") || x.type == "Variable") {
						x = this;
						print ("[");
						var com = false;
						while (x.type == "Term" && x.name == "cons" && x.partlist.list.length == 2) {
							if (com) print (", ");
							x.partlist.list[0].print();
							com = true;
							x = x.partlist.list[1];
						}
						if (x.type == "Variable") {
							print (" | ");
							x.print();
						}
						print ("]");
						return;
					}
				}
				print ("" + this.name + "(");
				this.partlist.print();
				print (")");
			};
		this.type = "Term";
	}

	function Partlist(list) {
		this.list = list;
		this.print =
			function () {
				for (var i = 0; i < this.list.length; i++) {
					this.list[i].print();
					if (i < this.list.length - 1)
						print (", ");
				}
			};
	}

	function Body(list) {
		this.list = list;
		this.print =
			function () {
				for (var i = 0; i < this.list.length; i++) {
					this.list[i].print();
					if (i < this.list.length - 1)
						print (", ");
				}
			};
	}

	function Rule(head) { return new Rule(head, null); }
	function Rule(head, bodylist) {
		this.head = head;
		if (bodylist != null)
			this.body = new Body(bodylist);
		else
			this.body = null;

		this.print =
			function () {
				if (this.body == null) {
					this.head.print();
					print (".\n");
				} else {
					this.head.print();
					print (" :- ");
					this.body.print();
					print (".\n");
				}
			};
	}        
        
// The Tiny-Prolog parser goes here.
	function Tokeniser(string) {
		this.remainder = string;
		this.current = null;
		this.type = null;	// "eof", "id", "var", "punc" etc.
		this.consume =
			function () {
				if (this.type == "eof") return;
				// Eat any leading WS
				var r = this.remainder.match(/^\s*(.*)$/);
				if (r) {
					this.remainder = r[1];
				}

				if (this.remainder == "") {
					this.current = null;
					this.type = "eof";
					return;
				}

				r = this.remainder.match(/^([\(\)\.,\[\]\|]|\:\-)(.*)$/);
				if (r) {
					this.remainder = r[2];
					this.current = r[1];
					this.type = "punc";
					return;
				}

				r = this.remainder.match(/^([A-Z][a-zA-Z0-9]*)(.*)$/);
				if (r) {
					this.remainder = r[2];
					this.current = r[1];
					this.type = "var";
					return;
				}

				// URLs in angle-bracket pairs
				r = this.remainder.match(/^(\<[^\>]*\>)(.*)$/);
				if (r) {
					this.remainder = r[2];
					this.current = r[1];
					this.type = "id";
					return;
				}

				// Quoted strings
				r = this.remainder.match(/^("[^"]*")(.*)$/);
				if (r) {
					this.remainder = r[2];
					this.current = r[1];
					this.type = "id";
					return;
				}

				r = this.remainder.match(/^([a-zA-Z0-9]*)(.*)$/);
				if (r) {
					this.remainder = r[2];
					this.current = r[1];
					this.type = "id";
					return;
				}

				this.current = null;
				this.type = "eof";

			};
		this.consume();	// Load up the first token.
	}

	var tokenstring;
	var currenttoken;

	function ParseRule(tk) {
		// A rule is a Head followed by . or by :- Body

		var h = ParseHead(tk);
		if (!h) return null;

		if (tk.current == ".") {
			// A simple rule.
			return new Rule(h);
		}

		if (tk.current != ":-") return null;
		tk.consume();
		var b = ParseBody(tk);

		if (tk.current != ".") return null;

		return new Rule(h, b);
	}

	function ParseHead(tk) {
		// A head is simply a term. (errors cascade back up)
		return ParseTerm(tk);
	}

	function ParseTerm(tk) {
		// Term -> id ( optParamList )

		if (tk.type != "id") return null;
		var name = tk.current;
		tk.consume();

		if (tk.current != "(") return null;
		tk.consume();

		var p = [];
		var i = 0;
		while (tk.current != ")") {
			if (tk.type == "eof") return null;

			var part = ParsePart(tk);
			if (part == null) return null;

			if (tk.current == ",") tk.consume();
			else if (tk.current != ")") return null;

			// Add the current Part onto the list...
			p[i++] = part;
		}
		tk.consume();

		return new Term(name, p);
	}

	// This was a beautiful piece of code. It got kludged to add [a,b,c|Z] sugar.
	function ParsePart(tk) {
		// Part -> var | id | id(optParamList)
		// Part -> [ listBit ] ::-> cons(...)
		if (tk.type == "var") {
			var n = tk.current;
			tk.consume();
			return new Variable(n);
		}

		if (tk.type != "id") {
			if (tk.type != "punc" || tk.current != "[") return null;
			// Parse a list (syntactic sugar goes here)
			tk.consume();
			// Special case: [] = new atom(nil).
			if (tk.type == "punc" && tk.current == "]") {
				tk.consume();
				return new Atom("nil");
			}

			// Get a list of parts into l
			var l = [], i=0;

			while (true) {
				var t = ParsePart(tk);
				if (t == null) return null;

				l[i++] = t;
				if (tk.current != ",") break;
				tk.consume();
			}

			// Find the end of the list ... "| Var ]" or "]".
			var append;
			if (tk.current == "|") {
				tk.consume();
				if (tk.type != "var") return null;
				append = new Variable(tk.current);
				tk.consume();
			} else {
				append = new Atom("nil");
			}
			if (tk.current != "]") return null;
			tk.consume();
			// Return the new cons.... of all this rubbish.
			for (i--; i>=0; i--) append = new Term("cons", [l[i], append]);
			return append;
		}
			
		var name = tk.current;
		tk.consume();

		if (tk.current != "(") return new Atom(name);
		tk.consume();

		var p = [];
		var i = 0;
		while (tk.current != ")") {
			if (tk.type == "eof") return null;

			var part = ParsePart(tk);
			if (part == null) return null;

			if (tk.current == ",") tk.consume();
			else if (tk.current != ")") return null;

			// Add the current Part onto the list...
			p[i++] = part;
		}
		tk.consume();

		return new Term(name, p);
	}

	function ParseBody(tk) {
		// Body -> Term {, Term...}

		var p = [];
		var i = 0;

		var t;
		while ((t = ParseTerm(tk)) != null) {
			p[i++] = t;
			if (tk.current != ",") break;
			tk.consume();
		}

		if (i == 0) return null;
		return p;
	}
        
        function StringToTerm( s ) {
            return ParseTerm( new Tokeniser( s ) );
        }

//         function generateUID() {
//             return ("0000" + (Math.random()*Math.pow(36,4) << 0).toString(36)).substr(-4);
//         }

//         function LabelData( text, color, imgSrc, uid, parent ) {
//             this.text = text;
//             this.color = color;
//             this.imgSrc = imgSrc;
//             this.uid = uid;
//             this.parent = parent;            
//         }

//         function TermToLabelList( term, parent ) {
//             var rslt = [];

//             var labelElems = term.partlist.list;
//             var labelTextTerm = labelElems[0];
//             var labelDisplayTerm = labelElems[1];

//             var labelTextTermElems = labelTextTerm.partlist.list;
//             var labelTextAtom = labelTextTermElems[0];
//             var labelText = labelTextAtom.name;

//             var labelDisplayTermElems = labelDisplayTerm.partlist.list;
//             var labelDisplayColorTerm = labelDisplayTermElems[0];
//             var labelDisplayColorAtom = labelDisplayColorTerm.partlist.list[0];
//             var labelDisplayColor = labelDisplayColorAtom.name;
//             var labelDisplayImgSrcTerm = labelDisplayTermElems[0];
//             var labelDisplayImgSrcAtom = labelDisplayImgSrcTerm.partlist.list[0];
//             var labelDisplayImgSrc = labelDisplayImgSrcAtom.name;

//             var labelUID = generateUID();

//             var labelParent = null;
//             if ( parent != null ) {
//                 labelParent = parent.uid;
//             };

//             var termLabelData =
//                 new LabelData(
//                     labelText,
//                     labelDisplayColor,
//                     labelDisplayImgSrc,
//                     labelUID,
//                     labelParent
//                 );

//             rslt[0] = termLabelData;

//             if ( term.name === "node" ) {
//                 var labelProgeny = labelElems[2];
//                 var labelProgenyTermList = labelProgeny.partlist.list;
//                 for ( var i = 0; i < labelProgenyTermList.length ; i++ ) {
//                     rslt = rslt.concat( TermToLabelList( labelProgenyTermList[i], termLabelData ) );
//                 }
//             }

//             return rslt;
//         }

//         function StringToLabelList( s ) {
//             var term = ParseTerm( new Tokeniser( s ) );
//             var acc = [];

//             if ( term.name === "and" ) {
//                 var subterms = term.partlist.list
//                 for( var i = 0; i < subterms.length ; i++ ) {
//                     acc = acc.concat( TermToLabelList( subterms[i], null ) );
//                 }
//             }
//             else {
//                 acc = acc.concat( TermToLabelList( term, null ) );
//             }
//             return acc;
//         }
    
    return {
        StringToTerm : StringToTerm,
        Tokeniser : Tokeniser,
        ParseTerm : ParseTerm,
        Variable : Variable,
        Atom : Atom,
        Term : Term,
        Partlist : Partlist,
        Body : Body,
        Rule : Rule,
        //LabelData : LabelData,
        //StringToLabelList : StringToLabelList
    }
} )();

