package ui.widget;

import ui.jq.JQ;
import ui.jq.JDialog;
import ui.model.ModelObj;
import ui.model.EventModel;
import ui.model.ModelEvents;

using ui.helper.StringHelper;

typedef LoginCompOptions = {
}

typedef LoginCompWidgetDef = {
	@:optional var options: LoginCompOptions;
	@:optional var user: User;

	@:optional var input_un: JQ;
	@:optional var input_pw: JQ;
	@:optional var placeholder_un: JQ;
	@:optional var placeholder_pw: JQ;
	
	var initialized: Bool;

	var _setUser: User->Void;
	var _buildDialog: Void->Void;
	var open: Void->Void;
	var _login: Void->Void;

	var _create: Void->Void;
	var destroy: Void->Void;
}

extern class LoginComp extends JQ {

	@:overload(function(cmd : String):Bool{})
	@:overload(function(cmd:String, opt:String, newVal:Dynamic):JQ{})
	function loginComp(?opts: LoginCompOptions): LoginComp;

	private static function __init__(): Void {
		untyped LoginComp = window.jQuery;
		var defineWidget: Void->LoginCompWidgetDef = function(): LoginCompWidgetDef {
			return {
		        _create: function(): Void {
		        	var self: LoginCompWidgetDef = Widgets.getSelf();
					var selfElement: JDialog = Widgets.getSelfElement();
		        	if(!selfElement.is("div")) {
		        		throw new ui.exception.Exception("Root of LoginComp must be a div element");
		        	}

		        	selfElement.addClass("loginComp").hide();

		        	var labels: JQ = new JQ("<div class='fleft'></div>").appendTo(selfElement);
		        	var inputs: JQ = new JQ("<div class='fleft'></div>").appendTo(selfElement);

		        	labels.append("<div class='labelDiv'><label id='un_label' for='login_un'>Username</label></div>");
		        	labels.append("<div class='labelDiv'><label for='login_pw'>Password</label></div>");
		        	self.input_un = new JQ("<input id='login_un' style='display: none;' class='ui-corner-all ui-state-active ui-widget-content'>").appendTo(inputs);
		        	self.placeholder_un = new JQ("<input id='login_un_f' class='placeholder ui-corner-all ui-widget-content' value='Please enter Username'>").appendTo(inputs);
		        	inputs.append("<br/>");
		        	self.input_pw = new JQ("<input type='password' id='login_pw' style='display: none;' class='ui-corner-all ui-state-active ui-widget-content'/>").appendTo(inputs);
		        	self.placeholder_pw = new JQ("<input id='login_pw_f' class='placeholder ui-corner-all ui-widget-content' value='Please enter Password'/>").appendTo(inputs);

		        	inputs.children("input").keypress(function(evt: JQEvent): Void {
		        			if(evt.keyCode == 13) {
		        				self._login();
		        			}
		        		});

		        	self.placeholder_un.focus(function(evt: JQEvent): Void {
		        			self.placeholder_un.hide();
		        			self.input_un.show().focus();
		        		});

		        	self.input_un.blur(function(evt: JQEvent): Void {
		        			if(self.input_un.val().isBlank()) {
			        			self.placeholder_un.show();
			        			self.input_un.hide();
		        			}
		        		});

		        	self.placeholder_pw.focus(function(evt: JQEvent): Void {
		        			self.placeholder_pw.hide();
		        			self.input_pw.show().focus();
		        		});

		        	self.input_pw.blur(function(evt: JQEvent): Void {
		        			if(self.input_pw.val().isBlank()) {
			        			self.placeholder_pw.show();
			        			self.input_pw.hide();
		        			}
		        		});

		        	EventModel.addListener(ModelEvents.User, new EventListener(function(user: User): Void {
	        				self._setUser(user);
		        			if(user == null) {
		        				self.open();
		        			}
		        		})
		        	);
		        },

		        initialized: false,

		        _login: function(): Void {
		        	var self: LoginCompWidgetDef = Widgets.getSelf();
					var selfElement: JDialog = Widgets.getSelfElement();

		        	var valid = true;
    				var login: Login = new Login();
    				login.username = self.input_un.val();
    				if(login.username.isBlank()) {
    					self.placeholder_un.addClass("ui-state-error");
    					valid = false;
    				}
    				login.password = self.input_pw.val();
    				if(login.password.isBlank()) {
    					self.placeholder_pw.addClass("ui-state-error");
    					valid = false;
    				}
    				if(!valid) return;
    				selfElement.find(".ui-state-error").removeClass("ui-state-error");
    				EventModel.change(ModelEvents.Login, login);
    				selfElement.jdialog("close");
	        	},

		        _buildDialog: function(): Void {
		        	var self: LoginCompWidgetDef = Widgets.getSelf();
					var selfElement: JDialog = Widgets.getSelfElement();

		        	self.initialized = true;

		        	var dlgOptions: JDialogOptions = {
		        		autoOpen: false,
		        		title: "Login",
		        		height: 230,
		        		width: 400,
		        		buttons: {
		        			"Login": function() {
		        				self._login();
		        			},
		        			"I\\\'m New": function() {

		        				JDialog.cur.jdialog("close");	
		        			}
		        		},
		        		beforeClose: function(evt: JQEvent, ui: UIJDialog): Dynamic {
		        			if(self.user == null || !self.user.hasValidSession()) {
		        				js.Lib.alert("A valid user is required to use the app");
		        				return false;
		        			}
		        			return null;
		        		}
		        	};
		        	selfElement.jdialog(dlgOptions);
		        },

		        _setUser: function(user: User): Void {
		        	var self: LoginCompWidgetDef = Widgets.getSelf();

		        	self.user = user;
	        	},

	        	open: function(): Void {
		        	var self: LoginCompWidgetDef = Widgets.getSelf();
					var selfElement: JDialog = Widgets.getSelfElement();

		        	if(!self.initialized) {
		        		self._buildDialog();
		        	}
		        	selfElement.children("#un_label").focus();
		        	self.input_un.blur();
	        		selfElement.jdialog("open");
        		},
		        
		        destroy: function() {
		            untyped JQ.Widget.prototype.destroy.call( JQ.curNoWrap );
		        }
		    };
		}
		JQ.widget( "ui.loginComp", defineWidget());
	}
}