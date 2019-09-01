package ui.common {
	
	import flash.display.DisplayObject;
	import flash.geom.Rectangle;
	
	/**
	 * Интерфейс размещаемой в плейсере графики
	 * 
	 * @version  1.0.1
	 * @author   meps
	 */
	public interface IGAligner {
		
		/** Собственная графика */
		function get view():DisplayObject;
		
		/** Вызывается при появлении плейсера */
		//function show():void;
		
		/** Вызывается при исчезании плейсера со сцены */
		//function hide():void;
		
		/** Вызывается при изменении размеров плейсера */
		function resize(rect:Rectangle):void;
		
		/** Уничтожение интерфейса; результат удаления контейнера или данного плейсхолдера */
		function destroy():void;
		
	}
	
}