package ui.common {
	
	/**
	 * Интерфейс скинуемых объектов
	 * 
	 * @version  1.0.1
	 * @author   meps
	 */
	public interface IGSkinnable {
		
		/** Обработчик обновления скина; вызывается синхронно сразу после регистрации */
		function skinUpdate(resourceId:String, data:*):void;
		
	}
	
}