package flicker.gui {
	
	import flicker.utils.printClass;
	
	/**
	 * Событие смены идентифицируемых элементов интерфейса
	 *
	 * @version  1.0.3
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
			mId = id;
			super(type);
		}
		
		/** Установленное состояние элемента */
		public function get id():String {
			return mId;
		}
		
		override public function toString():String {
			return printClass(this, "type", "id");
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var mId:String;
		
	}
}
