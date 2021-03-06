package ui.widget.score;

import snap.Snap;

class TimeMarker
{
	private var paper: Snap;
	private var width: Float;
	private var line:SnapElement;
	private var group:SnapElement;

	public function new(uberGroup:SnapElement, paper:Snap, width:Float) {
		this.paper = paper;
		this.width = width;
		this.group = paper.group(paper, [])
		                  .attr("id", "time-marker");
		uberGroup.append(this.group);

		drawTimeLine();
	}

	private function drawTimeLine() {
		var margin = 7;
		var y = 3*margin;
		var attrs = {
			strokeOpacity: 0.6,
			stroke: "#cccccc", 
			strokeWidth: 1
		};

	  	this.line = paper.line(margin, y, width - margin, y).attr(attrs);
	  	this.group.append(this.line);

	  	var interval:Float = (width - 2*margin) / 24;
		var x:Float = margin;
	  	for(i in 0...25) {
	  		switch(i) {
	  			case 0, 12, 24: 
	  				this.group.append(paper.line(x, y-margin, x, y+margin).attr(attrs));
	  				if(i == 0)
			  			this.group.append(paper.text(x+3, y - margin + 1, "2013").attr({fontSize: "8px"}));
		  			else if(i == 12)
		  				this.group.append(paper.text(x+3, y - margin + 1, "2012").attr({fontSize: "8px"}));
			  		if(i == 0 || i == 12)
			  			this.group.append(paper.text(x+10, y + margin, "Dec").transform("rotate(30," + x + "," + y + ")").attr({fontSize: "8px"}));
			  		x += interval;
		  		case 3, 15: 
	  				this.group.append(paper.line(x, y, x, y+margin+2).attr(attrs));
			  		this.group.append(paper.text(x+10, y + margin, "Sep").transform("rotate(30," + x + "," + y + ")").attr({fontSize: "8px"}));
			  		x += interval;
			  	case 6, 18: 
	  				this.group.append(paper.line(x, y, x, y+margin+2).attr(attrs));
			  		this.group.append(paper.text(x+10, y + margin, "Jun").transform("rotate(30," + x + "," + y + ")").attr({fontSize: "8px"}));
			  		x += interval;
			  	case 9, 21: 
	  				this.group.append(paper.line(x, y, x, y+margin+2).attr(attrs));
			  		this.group.append(paper.text(x+10, y + margin, "Mar").transform("rotate(30," + x + "," + y + ")").attr({fontSize: "8px"}));
			  		x += interval;

	  			case _: 
			  		this.group.append(paper.line(x, y, x, y+margin).attr(attrs));
			  		x += interval;
	  		}
	  	}
	}
}
