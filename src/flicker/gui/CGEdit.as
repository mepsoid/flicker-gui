package flicker.gui {
	
	import flicker.CGuiManager;
	import flicker.ILock;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	
	/**
	 * Редактируемое поле ввода
	 *
	 * @version  1.1.12
	 * @author   meps
	 */
	public class CGEdit extends CGInteractive implements ILock{
		
		public function CGEdit(src:* = null, name:String = null) {
			mEnable = true;
			mFocus = false;
			mValue = "";
			mLast = "";
			mPrompt = "";
			super(src, name);
			CGuiManager.register(this);
			eventSign(true, CGEvent.DOWN, onClick);
		}
		
		// ILock ///////////////////////////////////////////////////////////////
		
		public function lock():void {
			mLock = true;
			enable = false
		}
		
		public function unlock():void {
			mLock = false;
			enable = true;
		}
		
		/** Собственный идентификатор элемента */
		public function get lockId():String { return mLockId; }
		
		public function set lockId(value:String):void { mLockId = value; }
		
		////////////////////////////////////////////////////////////////////////
		
		
		/** Активность поля ввода */
		public function get enable():Boolean {
			return mEnable;
		}
		
		public function set enable(val:Boolean):void {
			if (val == mEnable)
				return;
			mEnable = val;
			doState();
			if (mField) {
				mField.type = mEnable ? TextFieldType.INPUT : TextFieldType.DYNAMIC;
				mField.selectable = mEnable;
			}
		}
		
		/** Значение поля ввода */
 		public function get value():String {
			if (mFocus && mField)
				return mField.text;
			return mValue;
		}
		
		public function set value(val:String):void {
			val = val.substr(0, mLimit);
			if (val == mValue)
				return;
			mValue = val ? val : "";
			mLast = mValue;
			redrawField();
			eventSend(new CGEventEdit(CGEventEdit.COMPLETE, mValue));
		}
		
		/** Сбросить поле ввода */
		public function clear():void {
			if (!mValue)
				return;
			mValue = "";
			mLast = "";
			redrawField();
			eventSend(new CGEventEdit(CGEventEdit.COMPLETE, mValue));
		}
		
		/** Приглашение для ввода текста */
		public function get prompt():String {
			return mPrompt;
		}
		
		public function set prompt(val:String):void {
			if (val == mPrompt)
				return;
			mPrompt = val ? val : "";
			redrawField();
		}
		
		/** Установить фокус ввода на поле */
		public function focus():void {
			if (mField && mField.stage && mField.stage.focus !== mField) {
				mField.stage.focus = mField;
				// курсор в конец текстового поля
				var end:int = mField.text.length;
				mField.setSelection(end, end);
			}
		}
		
		/** Снять фокус ввода с поля */
		public function unfocus():void {
			if (mField && mField.stage.focus === mField)
				mField.stage.focus = null;
		}
		
		/** Ограничения на вводимые символы */
		public function get restrict():String {
			return mRestrict;
		}
		
		public function set restrict(val:String):void {
			mRestrict = val;
			if (mField)
				mField.restrict = val;
		}
		
		/** Ограничение на максимальное количество символов */
		public function get limit():int {
			return mLimit;
		}
		
		public function set limit(val:int):void {
			if (limit < 0)
				return;
			mLimit = val;
			if (mField)
				mField.maxChars = mLimit;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		override protected function doStateValue():String {
			if (!mEnable)
				return DISABLE_STATE;
			if (mFocus)
				return EDIT_STATE;
			return mOver ? OVER_STATE : OUT_STATE;
		}
		
		override protected function onClipProcess():void {
			super.onClipProcess();
			var field:TextField = objectFind(FIELD_ID) as TextField;
			//trace("===", field === m_field);
			if (field !== mField) {
				// отписаться от событий старого поля
				if (mField) {
					if (mField.stage && mField.stage.focus === mField)
						mField.stage.focus = null;
					mField.removeEventListener(FocusEvent.FOCUS_IN, onFieldFocus);
					mField.removeEventListener(FocusEvent.FOCUS_OUT, onFieldUnfocus);
					mField.removeEventListener(Event.CHANGE, onFieldChange);
					mField.removeEventListener(KeyboardEvent.KEY_DOWN, onFieldKey);
					mField = null;
				}
				//m_field = field;
				// настроить новое поле и подписаться на его события
				if (field) {
					field.type = mEnable ? TextFieldType.INPUT : TextFieldType.DYNAMIC;
					field.selectable = mEnable;
					field.tabEnabled = false;
					field.addEventListener(FocusEvent.FOCUS_IN, onFieldFocus, false, 0, true);
					field.addEventListener(FocusEvent.FOCUS_OUT, onFieldUnfocus, false, 0, true);
					field.addEventListener(Event.CHANGE, onFieldChange, false, 0, true);
					field.addEventListener(KeyboardEvent.KEY_DOWN, onFieldKey, false, 0, true);
					//trace("onClipProcess", "focus:", m_focus, "already:", m_field.stage.focus === m_field);
				}
			}
			if (!field) {
				// поле не найдено
				mField = null;
				return;
			}
			// отмасштабировать относительно предка
			if (mField !== field) {
				mField = field;
				mFieldWidth = mField.width;
				mFieldHeight = mField.height;
			}
			var parent:DisplayObjectContainer = mField.parent;
			var matrix:Matrix = parent.transform.matrix;
			var coeffA:Number = matrix.a;
			var coeffD:Number = matrix.d;
			var width:int = mFieldWidth * coeffA;// m_field.width * coeffA;
			var height:int = mFieldHeight * coeffD;// m_field.height * coeffD;
			matrix = mField.transform.matrix;
			//trace("1", parent.name, width + "x" + height, matrix, coeffA + ":" + coeffD, m_field.getBounds(parent));
			matrix.a = 1.0 / coeffA;
			matrix.d = 1.0 / coeffD;
			mField.width = width;
			mField.height = height;
			mField.transform.matrix = matrix;
			mField.restrict = mRestrict;
			mField.maxChars = mLimit;
			//trace("2", m_field.width + "x" + m_field.height, matrix, coeffA + ":" + coeffD, m_field.getBounds(parent));
			//m_field.border = true;
			if (mFocus && mField.stage)
				// при необходимости установить фокус на поле
				mField.stage.focus = mField;
			redrawField();
		}
		
		override protected function onDestroy():void {
			if (mField) {
				mField.removeEventListener(FocusEvent.FOCUS_IN, onFieldFocus);
				mField.removeEventListener(FocusEvent.FOCUS_OUT, onFieldUnfocus);
				mField.removeEventListener(Event.CHANGE, onFieldChange);
				mField.removeEventListener(KeyboardEvent.KEY_DOWN, onFieldKey);
				mField = null;
			}
			eventSign(false,CGEvent.DOWN,onClick)
			super.onDestroy();
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private function onClick(e:CGEvent):void {
			if (!mField || !mField.stage)
				return;
			mField.stage.focus = mField;
		}
		
		/** Обработчик получения фокуса полем ввода */
		private function onFieldFocus(event:FocusEvent):void {
			if (!mEnable)
				return;
			// сохранить текущее сообщение для возможности к нему вернуться
			//trace("onFieldFocus", "focus:", m_focus, "already:", m_field.stage.focus === m_field);
			mLast = mValue;
			if (!mFocus) {
				mFocus = true;
				doState();
			}
			redrawField();
		}
		
		/** Обработчик потери фокуса полем ввода */
		private function onFieldUnfocus(event:FocusEvent):void {
			if (!mEnable)
				return;
			//trace("onFieldUnfocus", "focus:", m_focus, "already:", m_field.stage.focus === m_field);
			if (mFocus) {
				mFocus = false;
				doState();
			}
			redrawField();
			//eventSend(new CGEventEdit(CGEventEdit.COMPLETE, m_value));
			eventSend(new CGEventEdit(CGEventEdit.UNFOCUS));
		}
		
		/** Обработчик изменения текста в поле ввода сообщения */
		private function onFieldChange(event:Event):void {
			if (!mEnable)
				return;
			mValue = mField.text;
			eventSend(new CGEventEdit(CGEventEdit.CHANGE, value));
		}
		
		/** Обработчик нажатия клавиш в поле ввода сообщения */
		private function onFieldKey(event:KeyboardEvent):void {
			if (!mEnable)
				return;
			switch (event.keyCode) {
				case Keyboard.ESCAPE:
					// сбросить сообщение и снять фокус с поля ввода
					mValue = mLast;
					redrawField();
					if (mField.stage.focus === mField)
						mField.stage.focus = null;
					break;
				case Keyboard.ENTER:
					// подтверждение текста
					mValue = mField.text;
					mLast = mValue;
					redrawField();
					if (mField.stage.focus === mField)
						mField.stage.focus = null;
					// прервать обработку перевода строки
					event.stopPropagation();
					eventSend(new CGEventEdit(CGEventEdit.COMPLETE, mValue));
					break;
			}
		}
		
		/** Вывод текущего состояния в поле ввода */
		private function redrawField():void {
			if (!mField)
				return;
			mField.text = mValue || mFocus ? mValue : (mPrompt ? mPrompt : "");
		}
		
		////////////////////////////////////////////////////////////////////////
		
		/** Активность поля ввода */
		private var mEnable:Boolean;
		
		/** Флаг фокуса ввода */
		private var mFocus:Boolean;
		
		/** Значение поля ввода */
		private var mValue:String;
		
		/** Последнее активное значение поля ввода, к нему приводится поле в случае отказа */
		private var mLast:String;
		
		/** Текст приглашения к вводу */
		private var mPrompt:String;
		
		/** Ограничения на вводимые символы */
		private var mRestrict:String;
		
		/** Ограничение на количество вводимых символов */
		private var mLimit:int = 0;
		
		/** Используемое текстовое поле */
		private var mField:TextField;
		
		/** Закешированные точные размеры текстового поля */
		private var mFieldWidth:Number, mFieldHeight:Number;
		
		private static const OUT_STATE:String = "out";
		private static const OVER_STATE:String = "over";
		private static const EDIT_STATE:String = "edit";
		private static const DISABLE_STATE:String = "disable";
		
		private static const FIELD_ID:String = ".edit";
		
		////////////////////////////////////////////////////////////////////////
		
		private var mLock:Boolean = false;
		private var mLockId:String;
	}

}