package flicker.gui {
	
	import flicker.gui.CGProto;
	
	/**
	 * Внешнее управление состояниями
	 * 
	 * Элемент предназначен для непосредственного управления состояниями, чтобы
	 * не приходилось создавать промежуточные классы, задача которых только во
	 * включении внутренних элементов и управлении состояниями.
	 * 
	 * @version  1.0.1
	 * @author   meps
	 */
	public class CGState extends CGProto {
		
		public function CGState(src:* = null, name:String = null) {
			super(src, name);
			
		}
		
		/** Текущее состояние */
		public function get state():String {
			return m_state;
		}
		
		public function set state(val:String):void {
			doClipState(val, false);
		}
		
	}

}