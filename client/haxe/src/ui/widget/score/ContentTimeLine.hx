package ui.widget.score;

import snap.Snap;
import ui.model.ModelObj;
import js.html.*;
import m3.util.M;
import m3.jq.JQ;
import js.d3.*;

class ContentTimeLine {
	private static var initial_y_pos = 60;

	private static var next_y_pos:Int = initial_y_pos;
	private static var next_x_pos:Int = 10;
	private static var width:Int = 60;
 	private static var height:Int = 70;

	private var paper: Snap;
	private var connection: Connection;
	private var connectionElement:SnapElement;
	public var timeLineElement:SnapElement;

	private var contents: Array<Content>;
	private var contentElements: Array<SnapElement>;

 	private var startTime:Float;
 	private var endTime:Float;

 	private var time_line_x:Float;
 	private var time_line_y:Float;

 	private var initialWidth:Float;

 	public static function resetPositions(): Void {
		ContentTimeLine.next_y_pos = initial_y_pos;
		ContentTimeLine.next_x_pos = 10;
 	}

	public function new(paper:Snap, connection: Connection, startTime:Float, endTime:Float, initialWidth:Float) {
		this.paper      = paper;
		this.connection = connection;
		this.startTime  = startTime;
		this.endTime    = endTime;
		this.initialWidth = initialWidth;

		this.contents = new Array<Content>();
		this.contentElements = new Array<SnapElement>();

		if (ContentTimeLine.next_y_pos > initial_y_pos) {
			ContentTimeLine.next_y_pos += ContentTimeLine.height + 20;
		}
		ContentTimeLine.next_y_pos += 10;

	 	time_line_x = ContentTimeLine.next_x_pos;
	 	time_line_y = ContentTimeLine.next_y_pos;

   		connectionElement = createConnectionElement();

   		this.timeLineElement = paper.group(paper, [connectionElement]);
	}

	public function removeElements() {
		connectionElement.remove();

		var iter = contentElements.iterator();
		while (iter.hasNext()) {
			iter.next().remove();
		}
	}
	private function createConnectionElement(): SnapElement {
		var line = paper.line(time_line_x, time_line_y + height/2, initialWidth, time_line_y + height/2)
		                .attr({"class":"contentLine"});
		var ellipse = paper.ellipse(time_line_x + width/2, time_line_y + height/2, width/2, height/2);
		ellipse.attr({fill:"#fff", stroke:"#000", strokeWidth:"1px"});

		var imgSrc = M.getX(connection.profile.imgSrc,"media/default_avatar.jpg");
		var img = paper.image(imgSrc, time_line_x, time_line_y, width, height)
               				       .attr({"preserveAspectRatio":"true"});
        img.attr({mask: ellipse});

		var border_ellipse = paper.ellipse(time_line_x + width/2, time_line_y + height/2, width/2, height/2);
		var filter = paper.filter(Snap.filter_shadow(4, 4, 4, "#000000"));
		border_ellipse.attr({fill:"none", stroke:"#5c9ccc", strokeWidth:"1px", filter:filter});
		
		return paper.group(paper, [line, img, border_ellipse]);
	}

	public function addContent(content:Content):Void {
		contents.push(content);
		createContentElement(content);
	}

	private function createContentElement(content:Content):Void {
		var radius = 10;
		var gap    = 10;

		var x:Float = (this.endTime - content.created.getTime())/(this.endTime - this.startTime) * initialWidth + time_line_x + ContentTimeLine.width;
		var y:Float = time_line_y  + height/2;

		var ele:SnapElement;
		if (content.type == ContentType.TEXT) {
			addContentElement(content, createTextElement(cast(content, MessageContent), x, y, 40, 40));
		} else if (content.type == ContentType.IMAGE) {
			addContentElement(content, createImageElement(cast(content, ImageContent), x, y, 40, 40));
		} else if (content.type == ContentType.URL) {
			addContentElement(content, createLinkElement(cast(content, UrlContent), x, y, 20));
		} else if (content.type == ContentType.AUDIO) {
			addContentElement(content, createAudioElement(cast(content, AudioContent), x, y, 20, 20));
		}
	}

	private function cloneElement(ele:SnapElement):SnapElement {
		var clone = ele.clone();
		clone.attr({"contentType": ele.attr("contentType")});
		clone.attr({"id": ele.attr("id") + "-clone"});
		return clone;		
	}

	private function addContentElement(content:Content, ele:SnapElement) {
		ele.attr({"contentType": Std.string(content.type)});
		ele.attr({"id" : content.creator + "-" + content.uid});

		ele = ele.click(function(evt:Event):Void {
			var clone = cloneElement(ele);

			var after_anim = function() {
				var bbox = clone.getBBox();
				var cx = bbox.x + bbox.width/2;
				var cy = bbox.y + bbox.height/2;
				var g_id = clone.attr("id");
				var g_type = clone.attr("contentType");
				clone.remove();
				var ele:SnapElement = null;

				switch (g_type) {
					case "AUDIO":
						ele = paper.ellipse(cx, cy, bbox.width/2, bbox.height/2)
								   .attr({"class":"audioEllipse"});
					case "IMAGE":
						ele = paper.image(cast(content, ImageContent).imgSrc, bbox.x, bbox.y, bbox.width, bbox.height)
               				       .attr({"preserveAspectRatio":"true"});
					case "URL":
						ele = Shapes.createHexagon(paper, cx, cy, bbox.width/2)
                                    .attr({"class":"urlContent"});
					case "TEXT":
						ele = paper.rect(bbox.x, bbox.y, bbox.width, bbox.height, 5, 5)
		                			.attr({"class":"messageContentLarge"});
				}

				var g = paper.group(paper,[ele]);
				g.attr({"contentType": g_type});
				g.attr({"id": g_id});
				g.click(function(evt:Event){
					g.remove();
				});

				switch (g_type) {
					case "AUDIO":
						ForeignObject.appendAudioContent(g_id, bbox, cast(content, AudioContent));
//							case "IMAGE":
//								ForeignObject.appendImageContent(g_id, bbox, cast(content, ImageContent));
					case "URL":
						ForeignObject.appendUrlContent(g_id, bbox, cast(content, UrlContent));
					case "TEXT":
						ForeignObject.appendMessageContent(g_id, bbox, cast(content, MessageContent));
				}
			};

			clone.animate(
				{transform: "t10,10 s5"},
			    200, "", function(){clone.animate({transform: "t10,10 s4"},100, "", after_anim);}
			);		
		});

		this.contentElements.push(ele);
		this.timeLineElement.append(ele);	
	}

	private function splitText(text:String, max_chars:Float, ?max_lines:Float=0):Array<String> {
		var words = text.split(" ");
		var lines = new Array<String>();
		var line_no = 0;
		lines[line_no] = "";
		for (i in 0...words.length) {
			if (lines[line_no].length + words[i].length > max_chars) {
				line_no += 1;
				if (line_no == max_lines) {
					break;
				}
				lines[line_no] = "";
			} else {
				lines[line_no] += " ";
			}
			lines[line_no] += words[i];
		}
		return lines;
	}

	private function createTextElement(content:MessageContent, x:Float, y:Float, ele_width:Float, ele_height:Float):SnapElement {
		var rect = paper.rect(x - ele_width/2, y - ele_height/2, ele_width, ele_height, 3, 3)
		                .attr({"class":"messageContent"});
		var bbox:Dynamic = {
			cx: x,
			cy: y,
			width: ele_height,
			height: ele_height
		};
		var icon = Icons.messageIcon(bbox);
		return paper.group(paper, [rect,icon]);
	}

	private function createImageElement(content:ImageContent, x:Float, y:Float, ele_width:Float, ele_height:Float):SnapElement {
		var rect = paper.rect(x - ele_width/2, y - ele_height/2, ele_width, ele_height, 3, 3)
		                .attr({"class":"imageContent"});
		var bbox:Dynamic = {
			cx: x,
			cy: y,
			width: ele_height,
			height: ele_height
		};
		var icon = Icons.imageIcon(bbox);
		return paper.group(paper, [rect,icon]);
	}

	private function createLinkElement(content:UrlContent, x:Float, y:Float, radius:Float):SnapElement {
		var hex = Shapes.createHexagon(paper, x, y, radius)
		                .attr({"class":"urlContent"});
		var icon = Icons.linkIcon(hex.getBBox());
		return paper.group(paper, [hex, icon]);
	}

	private function createAudioElement(content:AudioContent, x:Float, y:Float, rx:Float, ry:Float):SnapElement {
		var ellipse = paper.ellipse(x, y, rx, ry)
			               .attr({"class":"audioEllipse"});
		var icon = Icons.audioIcon(ellipse.getBBox());

		return paper.group(paper, [ellipse, icon]);
	}
}