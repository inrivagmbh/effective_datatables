# These are expected to be called by a developer.  They are part of the datatables DSL.
module EffectiveDatatablesHelper

  def render_datatable(datatable, input_js: {}, buttons: true, charts: true, filters: true, simple: false, inline: false)
    raise 'expected datatable to be present' unless datatable

    datatable.attributes[:simple] = true if simple
    datatable.attributes[:inline] = true if inline

    datatable.view ||= self

    unless EffectiveDatatables.authorized?(controller, :index, datatable.collection_class)
      return content_tag(:p, "You are not authorized to view this datatable. (cannot :index, #{datatable.collection_class})")
    end

    charts = charts && datatable._charts.present?
    filters = filters && (datatable._scopes.present? || datatable._filters.present?)

    input_js[:buttons] = false if simple || !buttons

    effective_datatable_params = {
      id: datatable.to_param,
      class: ('effective-datatable ' + Array(datatable.table_html_class).join(' ')),
      data: {
        'bulk-actions' => datatable_bulk_actions(datatable),
        'columns' => datatable_columns(datatable),
        'cookie' => datatable.cookie_key,
        'display-length' => datatable.display_length,
        'display-order' => [datatable.order_index, datatable.order_direction].to_json().html_safe,
        'display-records' => datatable.to_json[:recordsFiltered],
        'display-start' => datatable.display_start,
        'inline' => datatable.inline?.to_s,
        'options' => (input_js || {}).to_json.html_safe,
        'reset' => datatable_reset(datatable),
        'simple' => datatable.simple?.to_s,
        'spinner' => icon('spinner'), # effective_bootstrap
        'source' => effective_datatables.datatable_path(datatable, {format: 'json'}),
        'total-records' => datatable.to_json[:recordsTotal]
      }
    }

    if (charts || filters) && !simple
      output = ''.html_safe

      if charts
        datatable._charts.each { |name, _| output << render_datatable_chart(datatable, name) }
      end

      if filters
        output << render_datatable_filters(datatable)
      end

      output << render(partial: 'effective/datatables/datatable',
        locals: { datatable: datatable, effective_datatable_params: effective_datatable_params }
      )

      output
    else
      render(partial: 'effective/datatables/datatable',
        locals: { datatable: datatable, effective_datatable_params: effective_datatable_params }
      )
    end
  end

  def render_inline_datatable(datatable)
    render_datatable(datatable, inline: true)
  end

  def render_simple_datatable(datatable)
    raise 'expected datatable to be present' unless datatable

    datatable.view ||= self

    unless EffectiveDatatables.authorized?(controller, :index, datatable.collection_class)
      return content_tag(:p, "You are not authorized to view this datatable. (cannot :index, #{datatable.collection_class})")
    end

    effective_datatable_params = {
      id: datatable.to_param,
      class: ('effective-datatable simple ' + Array(datatable.table_html_class).join(' ')),
      data: {}
    }

    render(partial: 'effective/datatables/datatable',
      locals: { datatable: datatable, effective_datatable_params: effective_datatable_params }
    )
  end

  def inline_datatable?
    params[:_datatable_id].present?
  end

  def inline_datatable
    return nil unless inline_datatable?
    return @_inline_datatable if @_inline_datatable

    datatable = EffectiveDatatables.find(params[:_datatable_id])
    datatable.view = self

    EffectiveDatatables.authorize!(self, :index, datatable.collection_class)

    @_inline_datatable ||= datatable
  end

end
