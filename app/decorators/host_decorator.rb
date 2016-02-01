class HostDecorator < Draper::Decorator
  delegate_all

  def fonticon
    nil
  end

  def listicon_image
    "100/vendor-#{vmm_vendor_display.downcase}.png"
  end
end
