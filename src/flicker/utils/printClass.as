package flicker.utils {
	
	import flash.utils.getQualifiedClassName;
	
	/** Распечатать класс с перечисленными атрибутами */
	public function printClass(target:Object, ... list):String {
		if (target == null)
			return "null";
		var name:String = getQualifiedClassName(target);
		var index:int = name.indexOf("::");
		if (index >= 0)
				name = name.substr(index + 2);
		//* нумерация всех распечатываемых объектов
		var enum:int = CObjectEnumerator.instance.check(target);
		name += "@" + enum.toString(16);
		//*/
		var values:String = "";
		for each (var attr:String in list)
			values += (values ? ", " : " ") + attr + ":" + (target.hasOwnProperty(attr) ? printObject(target[attr]) : "?");
		return "[" + name + values + "]";
	}
	
}
