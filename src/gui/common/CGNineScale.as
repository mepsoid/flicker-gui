package ui.common {
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	/**
	 * Контейнер с автоматическим сбросом масштабирования у всех внутренних клипов по 9-scale квадрантам
	 * 
	 * @version  1.0.1
	 * @author   meps
	 */
	public class CGNineScale extends CGProto {
		
		public function CGNineScale(src:* = null, name:String = null) {
			m_cache = new Dictionary();
			super(src, name);
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function onClipProcess():void {
			super.onClipProcess();
			// перебрать все клипы и задать коэффициенты масштабирования в соответствии с их положением
			var mc:MovieClip = clip;
			if (!mc)
				return;
			var rect:Rectangle = mc.scale9Grid;
			if (!rect)
				return;
			var spr:Shape = new Shape()
			mc.addChild(spr);
			var graph:Graphics = spr.graphics;
			graph.clear();
			graph.lineStyle(0, 0xFF0000);
			graph.drawRect(rect.x, rect.y, rect.width, rect.height);
			var bound:Rectangle = mc.getRect(mc.parent);
			graph = (mc.parent as MovieClip).graphics;
			graph.clear();
			graph.lineStyle(0, 0x00FF00);
			graph.drawRect(bound.x, bound.y, bound.width, bound.height);
			var inner:Rectangle = mc.getRect(null);
			var mcMatrix:Matrix = mc.transform.matrix;
			for each (var child:DisplayObject in mc) {
				var name:String = child.name;
				if (!name)
					// не выравнивать не поименованные клипы
					continue;
				var childMatrix:Matrix = child.transform.matrix;
				var item:TChildInfo;
				if (m_cache.hasOwnProperty(name)) {
					item = m_cache[name];
					if (item.target !== child) {
						// обновился экземпляр
						item.target = child;
						item.matrix = new Matrix(
							childMatrix.a, childMatrix.b,
							childMatrix.c, childMatrix.d,
							childMatrix.tx, childMatrix.ty
						);
					}
				} else {
					// новая запись
					item = new TChildInfo(child, new Matrix(
							childMatrix.a, childMatrix.b,
							childMatrix.c, childMatrix.d,
							childMatrix.tx, childMatrix.ty
						));
					m_cache[name] = item;
				}
				var x:Number = child.x;
				var y:Number = child.y;
				var kx:Number = bound.width / (inner.width - rect.width) / mcMatrix.a;// 1.0 / mcMatrix.a;
				var ky:Number = bound.height / (inner.height - rect.height) / mcMatrix.d;//1.0 / mcMatrix.d;
				if (x <= rect.left) {
					childMatrix.a = 1.0 / mcMatrix.a;
					//childMatrix.tx = (item.matrix.tx) / mcMatrix.a;
				} else if (x >= rect.right) {
					childMatrix.a = 1.0 / mcMatrix.a;
					//childMatrix.tx = (item.matrix.tx) / mcMatrix.a;
				} else {
					childMatrix.a = kx;
				}
				if (y <= rect.top) {
					childMatrix.d = 1.0 / mcMatrix.d;
					//childMatrix.ty = (item.matrix.ty) / mcMatrix.d;
				} else if (y >= rect.bottom) {
					childMatrix.d = 1.0 / mcMatrix.d;
					//childMatrix.ty = (item.matrix.ty) / mcMatrix.d;
				} else {
					childMatrix.d = ky;
				}
				child.transform.matrix = childMatrix;
			}
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_cache:Dictionary;
		
	}

}

import flash.display.DisplayObject;
import flash.geom.Matrix;

internal class TChildInfo {
	
	public var target:DisplayObject;
	public var matrix:Matrix;
	
	public function TChildInfo(_target:DisplayObject, _matrix:Matrix) {
		target = _target;
		matrix = _matrix;
	}
	
}
