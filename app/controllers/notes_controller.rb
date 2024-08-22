class NotesController < ApplicationController
  before_action :set_client
  before_action :set_note, only: [:edit, :update, :destroy]

  def new
    @client = Client.find(params[:client_id])
    @note = @client.notes.build
    authorize @note
  end

  def create
    @note = @client.notes.build(note_params)
    authorize @note
    if @note.save
      redirect_to user_client_notes_path(current_user, @client), notice: 'Note was successfully created.'
    else
      render :new
    end
  end

  def edit
    # @note is set by set_note
  end

  def update
    if @note.update(note_params)
      redirect_to user_client_notes_path(current_user, @client), notice: 'Note was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @note.destroy
    redirect_to user_client_notes_path(current_user, @client), notice: 'Note was successfully deleted.'
  end

  private

  def set_client
    @client = Client.find(params[:client_id])
  end

  def set_note
    @note = @client.notes.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:text)
  end
end
