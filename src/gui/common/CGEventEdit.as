package framework.gui {
	
	/**
	 * Событие изменения поля ввода текста
	 *
	 * @version  1.0.2
	 * @author   meps
	 */
	public class CGEventEdit extends CGEvent {
		
		/** Событие изменения текста */
		public static const CHANGE:String = "edit_change";
		
		/** Событие завершения ввода текста */
		public static const COMPLETE:String = "edit_complete";
		
		/** Событие потери фокуса */
		public static const UNFOCUS:String = "unfocus";
		
		public function CGEventEdit(type:String, text:String = null) {
			super(type);
			mText = text;
		}
		
		/** Текст поля ввода */
		public function get text():String {
			return mText;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var mText:String;
		
	}

}