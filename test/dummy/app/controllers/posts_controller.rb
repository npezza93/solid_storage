class PostsController < ApplicationController
  def index
    @posts = Post.all
  end

  def new
    @post = Post.new
  end

  def create
    Post.create(file: params[:post][:file])

    redirect_to posts_path
  end
end
