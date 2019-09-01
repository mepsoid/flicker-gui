package framework.gui {
	
	import framework.utils.printClass;
	
	/**
	 * Базовое событие элементов интерфейса
	 *
	 * @version  1.0.4
	 * @author   meps
	 */
	public class CGEvent {
		
		public static const OVER:String = "over";
		public static const OUT:String = "out";
		public static const DOWN:String = "down";
		public static const UP:String = "up";
		public static const CLICK:String = "click";
		
		public function CGEvent(type:String) {
			mType = type;
		}
		
		/** Тип события */
		public function get type():String {
			return mType;
		}
		
		/** Владелец события */
		public function get target():CGDispatcher {
			return mTarget;
		}
		
		public function toString():String {
			return printClass(this, "type");
		}
		
		////////////////////////////////////////////////////////////////////////
		
		internal function targetSet(target:CGDispatcher):void {
			mTarget = target;
		}
		
		////////////////////////////////////////////////////////////////////////
		
		private var mType:String;
		private var mTarget:CGDispatcher;
		
	}

}
