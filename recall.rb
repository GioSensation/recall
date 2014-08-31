require 'sinatra'
require 'data_mapper'
require 'sinatra/flash'

enable :sessions
register Sinatra::Flash

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/recall.db")

class Note
	include DataMapper::Resource
	property :id, Serial
	property :content, Text, :required => true
	property :complete, Boolean, :required => true, :default => false
	property :created_at, DateTime
	property :updated_at, DateTime
end

DataMapper.finalize.auto_upgrade!

helpers do
	include Rack::Utils
	alias_method :h, :escape_html
end

get '/rss.xml' do
	@notes = Note.all :order => :id.desc
	builder :rss
end

get '/' do
	@notes = Note.all :order => :id.desc
	@title = 'All Notes'
	if @notes.empty?
		flash[:error] = 'No notes found. Add your first below.'
	end
	erb :home
end

post '/' do
	n = Note.new
	n.content = params[:content]
	n.created_at = Time.now
	n.updated_at = Time.now
	if n.save
		flash[:notice] = 'Note created successfully.'
		redirect '/'
	else
		flash[:error] = 'Failed to save note.'
		redirect '/'
	end
end

get '/:id' do
	@note = Note.get params[:id]
	@title = "Edit note ##{params[:id]}"
	if @note
		erb :edit
	else
		flash[:error] = "Can't find that note, sorry."
		redirect '/'
	end
end

put '/:id' do
	n = Note.get params[:id]
	unless n
		flash[:error] = "Can't find that note, sorry."
		redirect '/'
	end
	n.content = params[:content]
	n.complete = params[:complete] ? 1: 0
	n.updated_at = Time.now
	if n.save
		flash[:notice] = "Note updated successfully"
		redirect '/'
	else
		flash[:error] = "Error updating note."
		redirect '/'
	end
end

get '/:id/delete' do
	@note = Note.get params[:id]
	@title = "Confirm deletion of note ##{params[:id]}"
	if @note
		erb :delete
	else
		flash[:error] = "Can't find that note."
		redirect '/'
	end
end

delete '/:id' do
	n = Note.get params[:id]
	if n.destroy
		flash[:notice] = "Note successfully deleted."
		redirect '/'
	else
		flash[:error] = "Error marking note as complete."
		redirect '/'
	end
end

get '/:id/complete' do
	n = Note.get params[:id]
	n.complete = n.complete ? 0 : 1 # flip it
	n.updated_at = Time.now
	n.save
	redirect '/'
end