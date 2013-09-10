package ui.widget;

import m3.jq.JQ;
import m3.jq.JQDroppable;
import m3.widget.Widgets;
import ui.model.ModelObj;
import ui.model.EventModel;
import ui.model.ModelEvents;
import m3.observable.OSet;
import m3.exception.Exception;

typedef ConnectionsListOptions = {
	@:optional var itemsClass: String;
}

typedef ConnectionsListWidgetDef = {
	var options: ConnectionsListOptions;
	// var connections: ObservableSet<Connection>;
	@:optional var connectionsMap: MappedSet<Connection, ConnectionComp>;
	var _create: Void->Void;
	var _setConnections: ObservableSet<Connection>->Void;
	var destroy: Void->Void;
}

@:native("$")
extern class ConnectionsList extends JQ {
	@:overload(function(cmd : String):Bool{})
	@:overload(function(cmd:String, opt:String, newVal:Dynamic):JQ{})
	function connectionsList(opts: ConnectionsListOptions): ConnectionsList;

	private static function __init__(): Void {
		var defineWidget: Void->ConnectionsListWidgetDef = function(): ConnectionsListWidgetDef {
			return {
		        options: {
		            // connections: null,
		            itemsClass: null
		        },

		        _create: function(): Void {
		        	var self: ConnectionsListWidgetDef = Widgets.getSelf();
					var selfElement: JQ = Widgets.getSelfElement();
					if(!selfElement.is("div")) {
		        		throw new Exception("Root of ConnectionsList must be a div element");
		        	}

		        	selfElement.addClass(Widgets.getWidgetClasses());

		        	EventModel.addListener(ModelEvents.AliasLoaded, new EventListener(function(alias: Alias) {
			                self._setConnections(alias.connectionSet);
			            })
			        );

		        	// EventModel.addListener(ModelEvents.User, new EventListener(function(user: User) {
			        //        	self._setConnections(user.currentAlias.connections);
			        //     })
			        // );
		        },

		        _setConnections: function(connections: ObservableSet<Connection>): Void {
		        	var self: ConnectionsListWidgetDef = Widgets.getSelf();
					var selfElement: JQ = Widgets.getSelfElement();

		        	selfElement.children(".connection").remove();
		        	
		        	var spacer: JQ = selfElement.children("#sideRightSpacer");
		        	self.connectionsMap = new MappedSet<Connection, ConnectionComp>(connections, function(conn: Connection): ConnectionComp {
		        			return new ConnectionComp("<div></div>").connectionComp({connection: conn});
		        		});
		        	self.connectionsMap.listen(function(connComp: ConnectionComp, evt: EventType): Void {
		            		if(evt.isAdd()) {
		            			spacer.before(connComp);
		            		} else if (evt.isUpdate()) {
		            			connComp.connectionComp("update");
		            		} else if (evt.isDelete()) {
		            			connComp.remove();
		            		}
		            	});
		        },
		        
		        destroy: function() {
		            untyped JQ.Widget.prototype.destroy.call( JQ.curNoWrap );
		        }
		    };
		}
		JQ.widget( "ui.connectionsList", defineWidget());
	}	
}