package framework.gui {
	
	import framework.utils.printClass;
	
	/**
	 * Объединяемая в группы радиокнопка
	 *
	 * @version  1.0.10
	 * @author   meps
	 */
	public class CGRadio extends CGButton {
		
		public function CGRadio(src:* = null, name:String = null, lab:String = null, val:* = null, app:CGRadio = null) {
			mSelect = false;
			mValue = val;
			mSibling = this;
			super(src, name, lab);
			if (app)
				radioAppend(app);
		}
		
		/** Флаг включенного состояния радиокнопки */
		public function get select():Boolean {
			return mSelect;
		}
		
		public function set select(val:Boolean):void {
			if (mSelect == val)
				return;
			mSelect = val;
			doState();
			if (mSelect) {
				// сбросить выбор со всех прочих радио в группе
				var radio:CGRadio = mSibling;
				while (radio !== this) {
					radio.mSelect = false;
					radio.doState();
					radio = radio.mSibling;
				}
				broadcastSelect();
			}
			onSelect();
		}
		
		/** Циклически переключить выбранную радиокнопку на следующую; если
		    никакая еще не выбрана, сделать текущую активной */
		public function selectNext():void {
			var radio:CGRadio = this;
			do {
				if (radio.mSelect) {
					radio.mSibling.select = true;
					return;
				}
				radio = radio.mSibling;
			} while (radio !== this)
			select = true;
		}
		
		/** Циклически переключить выбранную радиокнопку на предыдущую; если
		    никакая еще не выбрана, сделать текущую активной */
		public function selectPrev():void {
			var radio:CGRadio = this;
			do {
				if (radio.mSibling.mSelect) {
					radio.select = true;
					return;
				}
				radio = radio.mSibling;
			} while (radio !== this)
			select = true;
		}
		
		/** Связанное с данной кнопкой значение */
		public function get value():* {
			return mValue;
		}
		
		public function set value(val:*):void {
			mValue = val;
		}
		
		/** Текущее выбранное в группе значение */
		public function get valueSelected():* {
			var radio:CGRadio = this;
			do {
				if (radio.mSelect)
					return radio.mValue;
				radio = radio.mSibling;
			} while (radio !== this)
			return null;
		}
		
		public function set valueSelected(val:*):void {
			var radio:CGRadio =  this;
			do {
				if (radio.mValue == val) {
					radio.select = true;
					return;
				}
				radio = radio.mSibling;
			} while (radio !== this)
		}
		
		/** Экземпляр текущей выбранной радиокнопки */
		public function get radioSelected():CGRadio {
			var radio:CGRadio = this;
			do {
				if (radio.mSelect)
					return radio;
				radio = radio.mSibling;
			} while (radio !== this)
			return null;
		}
		
		/** Добавить данную радиокнопку к группе других */
		public function radioAppend(radio:CGRadio, val:* = null):void {
			if (val != null)
				mValue = val;
			if (mSibling !== this)
				// если радиокнопка уже принадлежит другой группе, то сначала выйти из нее
				radioRemove();
			// дополнить кольцевой список
			mSibling = radio.mSibling;
			radio.mSibling = this;
		}
		
		/** Удалить данную радиокнопку из группы других */
		public function radioRemove():void {
			if (mSibling === this)
				return;
			// найти предыдущую кнопку в группе
			var radio:CGRadio = mSibling;
			while (radio.mSibling !== this)
				radio = radio.mSibling;
			// изъять из кольцевого списка
			radio.mSibling = mSibling;
			mSibling = this;
		}
		
		override public function toString():String {
			return printClass(this, "over", "down", "enable", "select", "value");
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function doStateValue():String {
			return super.doStateValue() +
				"_" +
				(mSelect ? STATE_SELECT : STATE_REGULAR);
		}
		
		override protected function doButtonClick():void {
			select = true;
			super.doButtonClick();
		}
		
		override protected function onDestroy():void {
			radioRemove();
			mValue = null;
			mSibling = null;
			super.onDestroy();
		}
		
		protected function onSelect():void {
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Разослать событие выбора по всем радиокнопкам группы */
		private function broadcastSelect():void {
			var radio:CGRadio = this;
			do {
				radio.eventSend(new CGEventSelect(CGEventSelect.SELECT, mValue));
				radio = radio.mSibling;
			} while (radio && radio !== this)
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var mSelect:Boolean;
		private var mValue:*;
		private var mSibling:CGRadio; // кольцевой однонаправленный список
		
		private static const STATE_SELECT:String  = "select";
		private static const STATE_REGULAR:String = "regular";
		
	}

}
