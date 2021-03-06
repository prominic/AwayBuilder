package awaybuilder.desktop
{
    import flash.events.Event;
    
    import awaybuilder.CoreContext;
    import awaybuilder.controller.events.DocumentEvent;
    import awaybuilder.controller.events.DocumentRequestEvent;
    import awaybuilder.controller.events.MessageBoxEvent;
    import awaybuilder.controller.events.SceneReadyEvent;
    import awaybuilder.desktop.controller.CloseDocumentCommand;
    import awaybuilder.desktop.controller.DocumentRequestCommand;
    import awaybuilder.desktop.controller.OpenFromInvokeCommand;
    import awaybuilder.desktop.controller.SceneReadyCommand;
    import awaybuilder.desktop.controller.ShowMessageBoxCommand;
    import awaybuilder.desktop.controller.events.OpenFromInvokeEvent;
    import awaybuilder.desktop.model.DesktopDocumentService;
    import awaybuilder.desktop.view.components.EditedDocumentWarningWindow;
    import awaybuilder.desktop.view.mediators.ApplicationMediator;
    import awaybuilder.desktop.view.mediators.EditedDocumentWarningWindowMediator;
    import awaybuilder.desktop.view.mediators.LibraryApplicationMediator;
    import awaybuilder.model.IDocumentService;
    
    import org.robotlegs.base.ContextEvent;
    import org.robotlegs.base.MultiWindowFlexMediatorMap;
    import org.robotlegs.core.IMediatorMap;
	
	public class DesktopAppContext extends CoreContext
	{
		
		override protected function get mediatorMap():IMediatorMap
		{
			return _mediatorMap || (_mediatorMap = new MultiWindowFlexMediatorMap(contextView, injector.createChild(), reflector));
		}
		
		override public function startup():void
		{
			super.startup();
			
			if (CONFIG::MOONSHINE)
			{
				this.contextView.addEventListener(AwayBuilderLibMain.DISPOSE, dispose);
			}
			
			this.commandMap.mapEvent(SceneReadyEvent.READY, SceneReadyCommand);
			
			this.commandMap.mapEvent(DocumentRequestEvent.REQUEST_NEW_DOCUMENT, DocumentRequestCommand);
			this.commandMap.mapEvent(DocumentRequestEvent.REQUEST_OPEN_DOCUMENT, DocumentRequestCommand);
			this.commandMap.mapEvent(DocumentRequestEvent.REQUEST_IMPORT_DOCUMENT, DocumentRequestCommand);
			this.commandMap.mapEvent(DocumentRequestEvent.REQUEST_CLOSE_DOCUMENT, DocumentRequestCommand);
			
			this.commandMap.mapEvent(OpenFromInvokeEvent.OPEN_FROM_INVOKE, OpenFromInvokeCommand);
			
			this.commandMap.mapEvent(DocumentEvent.CLOSE_DOCUMENT, CloseDocumentCommand);
			
			this.commandMap.mapEvent(MessageBoxEvent.SHOW_MESSAGE_BOX, ShowMessageBoxCommand);
			
			this.injector.mapSingletonOf(IDocumentService, DesktopDocumentService);
			
			if (CONFIG::MOONSHINE)
			{
				this.mediatorMap.mapView(AwayBuilderLibMain, LibraryApplicationMediator);
			}
			else
			{
				this.mediatorMap.mapView(AwayBuilderApplication, ApplicationMediator);
			}
			
			this.mediatorMap.mapView(EditedDocumentWarningWindow, EditedDocumentWarningWindowMediator);
			
			this.mediatorMap.createMediator(this.contextView);
			
			this.dispatchEvent(new ContextEvent(ContextEvent.STARTUP));
		}
		
		private function dispose(event:Event):void
		{
			this.contextView.removeEventListener(AwayBuilderLibMain.DISPOSE, dispose);
			this.commandMap.unmapEvents();
			this.mediatorMap.unmapView(EditedDocumentWarningWindow);
			this.mediatorMap.removeMediatorByView(this.contextView);
			
			shutdown();
		}
	}
}