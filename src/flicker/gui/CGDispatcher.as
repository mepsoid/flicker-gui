package flicker.gui {
	
	import flash.utils.Dictionary;
	import flicker.utils.printClass;
	
	/**
	 * Диспетчер событий для графического интерфейса
	 * 
	 * @author   meps
	 * @version  1.0.3
	 */
	public class CGDispatcher {
		
		public function CGDispatcher() {
			mTypes = new Vector.<String>();
			mListeners = new Vector.<Dictionary>();
		}
		
		/** Отписаться сразу от всех событий */
		public function eventClear():void {
			mTypes.length = 0;
			mListeners.length = 0;
		}
		
		/** Подписка и отписка обработчиков событий */
		public function eventSign(sign:Boolean, type:String, listener:Function):void {
			var dict:Dictionary;
			var index:int = mTypes.indexOf(type);
			if (sign) {
				// подписаться
				if (index < 0) {
					index = mTypes.length;
					mTypes[index] = type;
					dict = new Dictionary(true);
					mListeners[index] = dict;
				} else {
					dict = mListeners[index];
				}
				dict[listener] = listener;
			} else {
				// отписаться
				if (index >= 0) {
					dict = mListeners[index];
					delete dict[listener];
				}
			}
		}
		
		/** Кинуть событие */
		public function eventSend(event:CGEvent):Boolean {
			event.targetSet(this);
			var index:int = mTypes.indexOf(event.type);
			if (index < 0)
				return false;
			var dict:Dictionary = mListeners[index];
			for each (var func:Function in dict)
				func.call(this, event);
			return true;
		}
		
		public function toString():String {
			return printClass(this);
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var mTypes:Vector.<String>;
		private var mListeners:Vector.<Dictionary>;
		
	}
	
}
