package flicker.gui {
	
	import flash.display.DisplayObjectContainer;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Dictionary;
	
	/**
	 * Масштабируемая кнопка с переопределением выравнивания текстового поля с лейблом
	 * 
	 * @version  1.0.4
	 * @author   meps
	 */
	public class CGButtonResizable extends CGButton {
		
		public function CGButtonResizable(src:* = null, name:String = null, lab:String = null) {
			m_cache = new Dictionary();
			super(src, name, lab);
		}
		
		override protected function onTextUpdate(field:TextField, textId:String, textValue:String):void {
			// заполнить текстом
			var fmt:TextFormat = field.getTextFormat();
			field.mouseEnabled = false;
			field.defaultTextFormat = fmt;
			if (textValue != null)
				field.text = textValue;
			// выровнять независимо от преобразований предка
			var parent:DisplayObjectContainer = field.parent;
			var matrix:Matrix = parent.transform.matrix;
			var coeffA:Number = matrix.a;
			var coeffD:Number = matrix.d;
			if (coeffA < coeffD) {
				coeffD = coeffA / coeffD;
				coeffA = 1.0;
			} else {
				coeffA = coeffD / coeffA;
				coeffD = 1.0;
			}
			//trace(parent.name, field.width + "x" + field.height, matrix, coeffA + ":" + coeffD, field.getBounds(parent));
			matrix = field.transform.matrix;
			field.transform.matrix = new Matrix(1, 0, 0, 1, matrix.tx, matrix.ty);
			// обновить данные о текстовых полях
			var data:TFieldData;
			if (m_cache.hasOwnProperty(textId)) {
				data = m_cache[textId];
				if (field !== data.field) {
					//trace("1:", "change");
					data.field = field;
					data.matrix = matrix.clone();
					//trace("CGButtonResizable::onTextUpdate", "change:", data);
				} else {
					//trace("CGButtonResizable::onTextUpdate", "equal:", data);
				}
			} else {
				data = new TFieldData(field, matrix.clone());
				//trace("CGButtonResizable::onTextUpdate", "new:", data);
				m_cache[textId] = data;
			}			
			matrix.a = coeffA;
			matrix.d = coeffD;
			matrix.tx = data.matrix.tx + data.field.width * (1.0 - coeffA) * 0.5;
			matrix.ty = data.matrix.ty + data.field.height * (1.0 - coeffD) * 0.5;
			field.transform.matrix = matrix;
			//trace("2:", field.width + "x" + field.height, matrix, coeffA + ":" + coeffD, field.getBounds(parent));
			//field.border = true;
		}
		
		override protected function onDestroy():void {
			m_cache = null;
			super.onDestroy();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Закешированные данные с характеристиками текстовых полей */
		private var m_cache:Dictionary;
		
	}

}

import flash.geom.Matrix;
import flash.text.TextField;
import services.printClass;

internal class TFieldData {
	
	/** Закешированный указатель на текстовое поле */
	public var field:TextField;
	
	/** Закешированная матрица преобразований текстового поля */
	public var matrix:Matrix;
	
	public function TFieldData(_field:TextField, _matrix:Matrix) {
		field = _field;
		matrix = _matrix;
	}
	
	public function toString():String {
		return printClass(this, "field", "matrix");
	}
	
}
