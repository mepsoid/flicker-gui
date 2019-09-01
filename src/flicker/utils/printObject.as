package flicker.utils {
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.xml.XMLNode;
	
	/** Распечатать произвольный объект */
	public function printObject(data:*):String {
		var result:String = "";
		if (data is DisplayObject) {
			if (data is TextField)
				result = printClass(data, "name", "x", "y", "width", "height", "text");
			else if (data is DisplayObjectContainer)
				result = printClass(data, "name", "x", "y", "width", "height", "numChildren");
			else
				result = printClass(data, "name", "x", "y", "width", "height");
		} else if (data is Array || data is String || data is Number || data is Boolean || data is Matrix) {
			result = data.toString();
		} else if (data is XML || data is XMLList || data is XMLNode) {
			result = data.toXMLString();
		} else if (data is Object) {
			for each (var ref:String in data)
				result += (result ? ", " : "") + ref + ":" + printObject(data[ref]);
			result = "{" + result + "}";
		}
		return result;
	}

}