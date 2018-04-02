package awaybuilder.desktop.controller
{
	import mx.core.FlexGlobals;
	
	import spark.components.Application;
	
	import awaybuilder.controller.events.DocumentRequestEvent;
	import awaybuilder.controller.scene.events.SceneEvent;
	import awaybuilder.desktop.view.components.EditedDocumentWarningWindow;
	import awaybuilder.model.ApplicationModel;
	import awaybuilder.model.DocumentModel;
	
	import org.robotlegs.mvcs.Command;
	
	public class DocumentRequestCommand extends Command
	{
		[Inject]
		public var event:DocumentRequestEvent;
		
		[Inject]
		public var documentModel:DocumentModel;
		
		[Inject]
		public var windowModel:ApplicationModel;
		
		override public function execute():void
		{
			if(event.type == DocumentRequestEvent.REQUEST_CLOSE_DOCUMENT)
			{
				if(this.windowModel.isWaitingForClose)
				{
					//we're already asking the user to do something
					return;
				}
				this.windowModel.isWaitingForClose = true;
			}
			
			if(this.documentModel.edited)
			{
				//deselect all so that the window doesn't interfere
				this.dispatch(new SceneEvent(SceneEvent.SELECT_NONE));
				
				var window:EditedDocumentWarningWindow = new EditedDocumentWarningWindow();
				this.mediatorMap.createMediator(window);
				
				if (CONFIG::MOONSHINE)
				{
					this.windowModel.savedNextEvent = this.event.nextEvent2Moonshine || this.event.nextEvent;
					window.open();
					window.nativeWindow.x = this.contextView.stage.nativeWindow.x + (this.contextView.stage.nativeWindow.width - window.nativeWindow.width) / 2;
					window.nativeWindow.y = this.contextView.stage.nativeWindow.y + (this.contextView.stage.nativeWindow.height - window.nativeWindow.height) / 2;
				}
				else
				{
					this.windowModel.savedNextEvent = this.event.nextEvent;
					var app:AwayBuilderApplication = FlexGlobals.topLevelApplication as AwayBuilderApplication;
					window.open();
					window.nativeWindow.x = app.nativeWindow.x + (app.nativeWindow.width - window.nativeWindow.width) / 2;
					window.nativeWindow.y = app.nativeWindow.y + (app.nativeWindow.height - window.nativeWindow.height) / 2;
				}
				return;
			}
			
			CONFIG::MOONSHINE
				{
					if (this.event.nextEvent2Moonshine)
					{
						// this will not force the editor to reload same file if nothing has changed
						if (this.documentModel.path == this.event.nextEvent2Moonshine.items[0]) 
						{
							AwayBuilderLibMain(contextView).isFileLoading = false;
							return;
						}
						
						this.dispatch(this.event.nextEvent2Moonshine);
						return;
					}
				}
				
			this.dispatch(this.event.nextEvent);
		}
	}
}