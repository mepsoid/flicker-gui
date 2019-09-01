package ui.common {
	
	import services.printClass;
	
	/**
	 * Событие смены идентифицируемых элементов интерфейса
	 *
	 * @version  1.0.2
	 * @author   meps
	 */
	public class CGEventChange extends CGEvent {
		
		/** Тип событие изменения текста */
		public static const TEXT:String = "change_text";
		
		/** Тип события изменения иконки */
		public static const ICON:String = "change_icon";
		
		/** Тип события изменения изображения */
		public static const IMAGE:String = "change_image";
		
		public function CGEventChange(type:String, id:String) {
			m_id = id;
			super(type);
		}
		
		/** Установленное состояние элемента */
		public function get id():String {
			return m_id;
		}
		
		override public function toString():String {
			return printClass(this, "type", "id");
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_id:String;
		
	}
}