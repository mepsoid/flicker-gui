package flicker.gui {
	
	import flash.display.DisplayObjectContainer;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	/**
	 * Текстовое поле со сбросим масштабирования
	 * 
	 * @version  1.0.2
	 * @author   meps
	 */
	public class CGLabelResizable extends CGProto {
		
		public function CGLabelResizable(src:*= null, name:String = null) {
			super(src, name);
		}
		
		override protected function onTextUpdate(field:TextField, textId:String, textValue:String):void {
			//super.onTextUpdate(field, textId, textValue);
			// заполнить текстом
			var fmt:TextFormat = field.getTextFormat();
			field.mouseEnabled = false;
			field.defaultTextFormat = fmt;
			if (textValue != null)
				field.text = textValue;
			// отмасштабировать относительно предка
			var parent:DisplayObjectContainer = field.parent;
			var matrix:Matrix = parent.transform.matrix;
			var coeffA:Number = matrix.a;
			var coeffD:Number = matrix.d;
			var width:int = field.width * coeffA;
			var height:int = field.height * coeffD;
			//trace(parent.name, width + "x" + height, matrix, coeffA + ":" + coeffD, field.getBounds(parent));
			matrix = field.transform.matrix;
			matrix.a = 1.0 / coeffA;
			matrix.d = 1.0 / coeffD;
			field.width = width;
			field.height = height;
			field.transform.matrix = matrix;
			//trace("2:", field.width + "x" + field.height, matrix, coeffA + ":" + coeffD, field.getBounds(parent));
			//field.border = true;
		}
		
	}

}