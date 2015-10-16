class EvidenceItemsController < ApplicationController
  include WithComment
  include WithSoftDeletion

  actions_without_auth :index, :show, :variant_index, :variant_hgvs_index, :advanced_search

  def index
    items = EvidenceItem.view_scope
      .page(params[:page].to_i)
      .per(params[:count].to_i)

    render json: limit_query_by_status(items).map { |item| EvidenceItemPresenter.new(item) }
  end

  def variant_index
    items = EvidenceItem.view_scope
      .page(params[:page].to_i)
      .per(params[:count].to_i)
      .joins(:variant)
      .where(variants: { id: params[:variant_id] })

    render json: limit_query_by_status(items).map { |item| EvidenceItemPresenter.new(item) }
  end

  def variant_hgvs_index
    json = EvidenceItem.where.not(:variant_hgvs => "N/A")
      .pluck(:variant_hgvs, :variant_id, :id).to_json
    render json: json
  end

  def propose
    item = EvidenceItem.propose_new(evidence_item_params, relational_params)
    authorize item
    attach_comment(item)
    create_event(item)
    render json: item.state_params
  end

  def accept
    item = EvidenceItem.view_scope.find_by!(id: params[:evidence_item_id])
    authorize item
    item.accept!(current_user)
    render json: EvidenceItemPresenter.new(item, true)
  end

  def reject
    item = EvidenceItem.view_scope.find_by!(id: params[:evidence_item_id])
    authorize item
    item.reject!(current_user)
    render json: EvidenceItemPresenter.new(item, true)
  end

  def show
    item = EvidenceItem.view_scope
      .find_by!(id: params[:id])

    render json: EvidenceItemPresenter.new(item, true)
  end

  def destroy
    item = EvidenceItem.view_scope
      .find_by!(id: params[:id])
    authorize :item
    soft_delete(item, EvidenceItemPresenter)
  end

  def advanced_search
    searcher = AdvancedEvidenceItemSearch.new(params)
    render json: searcher.search.map { |ei| EvidenceItemWithStateParamsPresenter.new(ei, false) }
  end

  private
  def limit_query_by_status(query)
    if params[:status].present?
      query.where(status: params[:status])
    else
      query
    end
  end

  def evidence_item_params
    params.permit(
      :text,
      :clinical_significance,
      :evidence_direction,
      :rating,
      :description,
      :evidence_type,
      :evidence_level,
      :variant_origin,
      :drug_interaction_type,
    )
  end

  def relational_params
    params.permit(
      :noDoid,
      :pubmed_id,
      :disease_name,
      :drugs,
      drugs: [],
      gene: [:id, :entrez_id],
      disease: [:id],
      variant: [:id, :name]
    )
  end

  def create_event(item)
    Event.create(
      action: 'submitted',
      originating_user: current_user,
      subject: item
    )
  end
end
