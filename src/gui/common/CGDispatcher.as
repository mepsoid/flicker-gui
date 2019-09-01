package ui.common {
	
	import flash.utils.Dictionary;
	import services.printClass;
	
	/**
	 * Диспетчер событий для графического интерфейса
	 * 
	 * @author   meps
	 * @version  1.0.2
	 */
	public class CGDispatcher {
		
		public function CGDispatcher() {
			m_types = new Vector.<String>();
			m_listeners = new Vector.<Dictionary>();
		}
		
		/** Отписаться сразу от всех событий */
		public function eventClear():void {
			m_types.length = 0;
			m_listeners.length = 0;
		}
		
		/** Подписка и отписка обработчиков событий */
		public function eventSign(sign:Boolean, type:String, listener:Function):void {
			var dict:Dictionary;
			var index:int = m_types.indexOf(type);
			if (sign) {
				// подписаться
				if (index < 0) {
					index = m_types.length;
					m_types[index] = type;
					dict = new Dictionary(true);
					m_listeners[index] = dict;
				} else {
					dict = m_listeners[index];
				}
				dict[listener] = listener;
			} else {
				// отписаться
				if (index >= 0) {
					dict = m_listeners[index];
					delete dict[listener];
				}
			}
		}
		
		/** Кинуть событие */
		public function eventSend(event:CGEvent):Boolean {
			event.targetSet(this);
			var index:int = m_types.indexOf(event.type);
			if (index < 0)
				return false;
			var dict:Dictionary = m_listeners[index];
			for each (var func:Function in dict)
				func.call(this, event);
			return true;
		}
		
		public function toString():String {
			return printClass(this);
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var m_types:Vector.<String>;
		private var m_listeners:Vector.<Dictionary>;
		
	}
}